package main

import (
	"archive/zip"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"
)

const maxArchive = int64(256 << 20)
const maxExpanded = int64(512 << 20)
const entrypoint = "Nocturne/Nocturne.exe"

var versionPattern = regexp.MustCompile(`^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$`)

type Config struct {
	Schema      int    `json:"schema"`
	ManifestURL string `json:"manifest_url"`
}
type Manifest struct {
	Schema  int    `json:"schema"`
	Version string `json:"version"`
	URL     string `json:"url"`
	SHA256  string `json:"sha256"`
	Bytes   int64  `json:"bytes"`
}
type Installed struct {
	Version  string `json:"version"`
	Previous string `json:"previous,omitempty"`
}
type Updater struct {
	Root   string
	Config Config
	Client *http.Client
	// Only unit tests can permit an HTTP test server; configuration cannot enable this.
	allowHTTP bool
}

func newUpdater(root string, cfg Config) *Updater {
	return &Updater{Root: root, Config: cfg, Client: &http.Client{Timeout: 75 * time.Second, CheckRedirect: func(req *http.Request, via []*http.Request) error {
		if len(via) >= 8 {
			return errors.New("too many redirects")
		}
		if req.URL.Scheme != "https" {
			return errors.New("update redirect must use HTTPS")
		}
		return nil
	}}}
}
func validVersion(s string) bool { return len(s) < 40 && versionPattern.MatchString(s) }
func newer(a, b string) bool {
	if !validVersion(a) || !validVersion(b) {
		return false
	}
	aa, bb := strings.Split(a, "."), strings.Split(b, ".")
	for i := 0; i < 3; i++ {
		x, err := strconv.ParseUint(aa[i], 10, 64)
		if err != nil {
			return false
		}
		y, err := strconv.ParseUint(bb[i], 10, 64)
		if err != nil {
			return false
		}
		if x != y {
			return x > y
		}
	}
	return false
}
func validateManifest(m Manifest) error {
	if m.Schema != 1 || !validVersion(m.Version) {
		return errors.New("unsupported release manifest")
	}
	sum, err := hex.DecodeString(m.SHA256)
	if err != nil || len(sum) != 32 {
		return errors.New("invalid release checksum")
	}
	if m.Bytes <= 0 || m.Bytes > maxArchive {
		return errors.New("release size outside supported limits")
	}
	return nil
}
func (u *Updater) validateURL(raw string) error {
	parsed, err := url.Parse(raw)
	if err != nil || parsed.Host == "" || parsed.User != nil || parsed.Fragment != "" {
		return errors.New("invalid update URL")
	}
	if parsed.Scheme != "https" && !(u.allowHTTP && parsed.Scheme == "http") {
		return errors.New("updates require HTTPS")
	}
	return nil
}
func readJSON(path string, dst any) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()
	return json.NewDecoder(io.LimitReader(f, 65536)).Decode(dst)
}
func writeJSON(path string, value any) error {
	data, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		return err
	}
	tmp, err := os.CreateTemp(filepath.Dir(path), ".state-*.tmp")
	if err != nil {
		return err
	}
	name := tmp.Name()
	defer os.Remove(name)
	if err = tmp.Chmod(0600); err == nil {
		_, err = tmp.Write(data)
	}
	if err == nil {
		err = tmp.Sync()
	}
	closeErr := tmp.Close()
	if err != nil {
		return err
	}
	if closeErr != nil {
		return closeErr
	}
	return os.Rename(name, path)
}
func (u *Updater) current() (Installed, error) {
	var state Installed
	err := readJSON(filepath.Join(u.Root, "current.json"), &state)
	if err != nil {
		return state, err
	}
	if !validVersion(state.Version) || (state.Previous != "" && !validVersion(state.Previous)) {
		return state, errors.New("invalid installed version")
	}
	return state, nil
}
func (u *Updater) executable(version string) (string, error) {
	if !validVersion(version) {
		return "", errors.New("invalid version")
	}
	path := filepath.Join(u.Root, "versions", version, filepath.FromSlash(entrypoint))
	info, err := os.Stat(path)
	if err != nil {
		return "", err
	}
	if !info.Mode().IsRegular() {
		return "", errors.New("game executable missing")
	}
	return path, nil
}
func (u *Updater) manifest() (Manifest, error) {
	var m Manifest
	if u.Config.Schema != 1 {
		return m, errors.New("unsupported launcher configuration")
	}
	if err := u.validateURL(u.Config.ManifestURL); err != nil {
		return m, err
	}
	response, err := u.Client.Get(u.Config.ManifestURL)
	if err != nil {
		return m, err
	}
	defer response.Body.Close()
	if response.StatusCode != 200 {
		return m, fmt.Errorf("release manifest returned HTTP %d", response.StatusCode)
	}
	if err = json.NewDecoder(io.LimitReader(response.Body, 65536)).Decode(&m); err != nil {
		return m, err
	}
	if err = validateManifest(m); err != nil {
		return m, err
	}
	if err = u.validateURL(m.URL); err != nil {
		return m, err
	}
	return m, nil
}
func (u *Updater) checkForUpdate() (bool, error) {
	m, err := u.manifest()
	if err != nil {
		return false, err
	}
	old, oldErr := u.current()
	if oldErr == nil && !newer(m.Version, old.Version) {
		if _, err = u.executable(old.Version); err == nil {
			return false, nil
		}
	}
	fmt.Println("Downloading Nocturne " + m.Version + "...")
	response, err := u.Client.Get(m.URL)
	if err != nil {
		return false, err
	}
	defer response.Body.Close()
	if response.StatusCode != 200 {
		return false, fmt.Errorf("game download returned HTTP %d", response.StatusCode)
	}
	archive, err := os.CreateTemp(u.Root, ".download-*.zip")
	if err != nil {
		return false, err
	}
	path := archive.Name()
	defer os.Remove(path)
	hash := sha256.New()
	count, copyErr := io.Copy(io.MultiWriter(archive, hash), io.LimitReader(response.Body, m.Bytes+1))
	closeErr := archive.Close()
	if copyErr != nil {
		return false, copyErr
	}
	if closeErr != nil {
		return false, closeErr
	}
	if count != m.Bytes || !strings.EqualFold(hex.EncodeToString(hash.Sum(nil)), m.SHA256) {
		return false, errors.New("download checksum or size mismatch; current version retained")
	}
	if err = u.installArchive(path, m); err != nil {
		return false, err
	}
	return true, nil
}
func (u *Updater) installArchive(archive string, m Manifest) error {
	if err := validateManifest(m); err != nil {
		return err
	}
	file, err := os.Open(archive)
	if err != nil {
		return err
	}
	hash := sha256.New()
	n, err := io.Copy(hash, io.LimitReader(file, maxArchive+1))
	file.Close()
	if err != nil {
		return err
	}
	if n != m.Bytes || !strings.EqualFold(hex.EncodeToString(hash.Sum(nil)), m.SHA256) {
		return errors.New("release checksum or size mismatch")
	}
	versions := filepath.Join(u.Root, "versions")
	if err = os.MkdirAll(versions, 0700); err != nil {
		return err
	}
	final := filepath.Join(versions, m.Version)
	if _, err = os.Stat(final); err == nil {
		// Never reuse or overwrite an unverified existing version directory.
		return errors.New("release version already exists; keep existing installation")
	} else if !os.IsNotExist(err) {
		return err
	}
	temp, err := os.MkdirTemp(versions, ".staging-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(temp)
	if err = extractArchive(archive, temp); err != nil {
		return err
	}
	old, _ := u.current()
	if err = os.Rename(temp, final); err != nil {
		return err
	}
	state := Installed{Version: m.Version}
	if validVersion(old.Version) && old.Version != m.Version {
		state.Previous = old.Version
	}
	if err = writeJSON(filepath.Join(u.Root, "current.json"), state); err != nil {
		os.RemoveAll(final)
		return err
	}
	return nil
}
func extractArchive(archive, destination string) error {
	reader, err := zip.OpenReader(archive)
	if err != nil {
		return err
	}
	defer reader.Close()
	if len(reader.File) > 128 {
		return errors.New("release contains too many files")
	}
	var total uint64
	seen := map[string]bool{}
	foundExe := false
	for _, f := range reader.File {
		clean := filepath.FromSlash(f.Name)
		// Reject both Windows and Unix traversal regardless of test host OS.
		if !filepath.IsLocal(clean) || strings.ContainsAny(f.Name, `\:`) || strings.HasPrefix(f.Name, "/") || strings.Contains(f.Name, "../") {
			return errors.New("unsafe archive path")
		}
		key := strings.ToLower(filepath.ToSlash(clean))
		if seen[key] {
			return errors.New("duplicate archive path")
		}
		seen[key] = true
		if f.Mode()&os.ModeSymlink != 0 {
			return errors.New("archive symlink rejected")
		}
		target := filepath.Join(destination, clean)
		if f.FileInfo().IsDir() {
			if err = os.MkdirAll(target, 0700); err != nil {
				return err
			}
			continue
		}
		if !f.Mode().IsRegular() {
			return errors.New("unsupported archive file type")
		}
		if f.UncompressedSize64 > uint64(maxExpanded) || total > uint64(maxExpanded)-f.UncompressedSize64 {
			return errors.New("expanded release too large")
		}
		total += f.UncompressedSize64
		if err = os.MkdirAll(filepath.Dir(target), 0700); err != nil {
			return err
		}
		source, e := f.Open()
		if e != nil {
			return e
		}
		dest, e := os.OpenFile(target, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0600)
		if e != nil {
			source.Close()
			return e
		}
		written, copyErr := io.Copy(dest, io.LimitReader(source, int64(f.UncompressedSize64)+1))
		source.Close()
		closeErr := dest.Close()
		if copyErr != nil {
			return copyErr
		}
		if closeErr != nil {
			return closeErr
		}
		if written != int64(f.UncompressedSize64) {
			return errors.New("archive length mismatch")
		}
		if filepath.ToSlash(clean) == entrypoint {
			foundExe = true
		}
	}
	if !foundExe {
		return errors.New("release has no Nocturne executable")
	}
	return nil
}
func (u *Updater) rollback() error {
	state, err := u.current()
	if err != nil {
		return err
	}
	if state.Previous == "" {
		return errors.New("no previous version is installed")
	}
	if _, err = u.executable(state.Previous); err != nil {
		return err
	}
	return writeJSON(filepath.Join(u.Root, "current.json"), Installed{Version: state.Previous, Previous: state.Version})
}
func (u *Updater) runGame() error {
	state, err := u.current()
	if err != nil {
		return err
	}
	executable, err := u.executable(state.Version)
	if err != nil {
		return err
	}
	cmd := exec.Command(executable)
	cmd.Dir = filepath.Dir(executable)
	start := time.Now()
	err = cmd.Run()
	if err != nil && time.Since(start) < 15*time.Second && state.Previous != "" {
		if rollbackErr := u.rollback(); rollbackErr != nil {
			return fmt.Errorf("game failed to start; rollback failed: %w", rollbackErr)
		}
		state, _ = u.current()
		executable, err = u.executable(state.Version)
		if err != nil {
			return err
		}
		cmd = exec.Command(executable)
		cmd.Dir = filepath.Dir(executable)
		return cmd.Run()
	}
	return err
}
