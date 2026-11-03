package main

import (
	"archive/zip"
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func archiveBytes(t *testing.T, files map[string]string) []byte {
	t.Helper()
	var b bytes.Buffer
	z := zip.NewWriter(&b)
	for name, body := range files {
		w, err := z.Create(name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err = w.Write([]byte(body)); err != nil {
			t.Fatal(err)
		}
	}
	if err := z.Close(); err != nil {
		t.Fatal(err)
	}
	return b.Bytes()
}
func manifestFor(data []byte, version, url string) Manifest {
	sum := sha256.Sum256(data)
	return Manifest{Schema: 1, Version: version, URL: url, SHA256: hex.EncodeToString(sum[:]), Bytes: int64(len(data))}
}
func installFixture(t *testing.T, u *Updater, version string) {
	t.Helper()
	data := archiveBytes(t, map[string]string{entrypoint: "game-" + version})
	path := filepath.Join(t.TempDir(), "game.zip")
	if err := os.WriteFile(path, data, 0600); err != nil {
		t.Fatal(err)
	}
	if err := u.installArchive(path, manifestFor(data, version, "https://example.com/game.zip")); err != nil {
		t.Fatal(err)
	}
}
func TestVersions(t *testing.T) {
	for _, pair := range [][2]string{{"0.1.10", "0.1.9"}, {"1.0.0", "0.99.99"}, {"0.2.0", "0.1.99"}} {
		if !newer(pair[0], pair[1]) {
			t.Fatal(pair)
		}
	}
	for _, v := range []string{"../escape", "v1.0.0", "01.0.0", "1.0", "1.2.3-beta", "1.0.0/evil"} {
		if validVersion(v) {
			t.Fatal(v)
		}
	}
	if newer("0.1.1", "0.1.1") || newer("0.1.0", "0.1.1") {
		t.Fatal("updater downgrades or reinstalls")
	}
}
func TestInstallRollbackAndSavePreservation(t *testing.T) {
	root := t.TempDir()
	u := newUpdater(root, Config{Schema: 1})
	saves := filepath.Join(root, "case.json")
	os.WriteFile(saves, []byte("existing save"), 0600)
	installFixture(t, u, "0.1.1")
	installFixture(t, u, "0.1.2")
	current, err := u.current()
	if err != nil || current.Version != "0.1.2" || current.Previous != "0.1.1" {
		t.Fatal(current, err)
	}
	if err = u.rollback(); err != nil {
		t.Fatal(err)
	}
	current, _ = u.current()
	if current.Version != "0.1.1" {
		t.Fatal(current)
	}
	saved, _ := os.ReadFile(saves)
	if string(saved) != "existing save" {
		t.Fatal("save was changed")
	}
	if _, err = u.executable("0.1.2"); err != nil {
		t.Fatal("previous build removed", err)
	}
}
func TestDownloadUpdateAndRejectBadChecksum(t *testing.T) {
	data := archiveBytes(t, map[string]string{entrypoint: "new game"})
	var m Manifest
	var downloads int
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/manifest" {
			json.NewEncoder(w).Encode(m)
			return
		}
		downloads++
		w.Write(data)
	}))
	defer server.Close()
	u := newUpdater(t.TempDir(), Config{Schema: 1, ManifestURL: server.URL + "/manifest"})
	u.Client = server.Client()
	u.allowHTTP = true
	installFixture(t, u, "0.1.1")
	m = manifestFor(data, "0.1.2", server.URL+"/game.zip")
	changed, err := u.checkForUpdate()
	if err != nil || !changed {
		t.Fatal(changed, err)
	}
	state, _ := u.current()
	if state.Version != "0.1.2" {
		t.Fatal(state)
	}
	changed, err = u.checkForUpdate()
	if err != nil || changed || downloads != 1 {
		t.Fatal("same version was downloaded again", downloads, err)
	}
	m.Version = "0.1.3"
	m.SHA256 = strings.Repeat("0", 64)
	if _, err = u.checkForUpdate(); err == nil {
		t.Fatal("bad checksum accepted")
	}
	state, _ = u.current()
	if state.Version != "0.1.2" {
		t.Fatal("failed download switched active version")
	}
	paths, _ := filepath.Glob(filepath.Join(u.Root, ".download-*"))
	if len(paths) != 0 {
		t.Fatal("temporary download leaked")
	}
}
func TestOfflineRetainsPlayableVersion(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { http.Error(w, "unavailable", 503) }))
	defer server.Close()
	u := newUpdater(t.TempDir(), Config{Schema: 1, ManifestURL: server.URL})
	u.Client = server.Client()
	u.allowHTTP = true
	installFixture(t, u, "0.1.1")
	if _, err := u.checkForUpdate(); err == nil {
		t.Fatal("offline error not reported")
	}
	current, _ := u.current()
	if _, err := u.executable(current.Version); err != nil {
		t.Fatal("offline game lost", err)
	}
}
func TestUnsafeArchivesNeverActivate(t *testing.T) {
	for _, name := range []string{"../outside.exe", "/outside.exe", `..\outside.exe`, `C:\outside.exe`, "Nocturne/../../outside.exe"} {
		t.Run(name, func(t *testing.T) {
			u := newUpdater(t.TempDir(), Config{Schema: 1})
			installFixture(t, u, "0.1.1")
			data := archiveBytes(t, map[string]string{entrypoint: "game", name: "bad"})
			file := filepath.Join(t.TempDir(), "bad.zip")
			os.WriteFile(file, data, 0600)
			if err := u.installArchive(file, manifestFor(data, "0.1.2", "https://example.com/game.zip")); err == nil {
				t.Fatal("unsafe archive accepted")
			}
			current, _ := u.current()
			if current.Version != "0.1.1" {
				t.Fatal("unsafe archive activated")
			}
		})
	}
}
func TestMissingExeAndInterruptedArchive(t *testing.T) {
	for _, data := range [][]byte{archiveBytes(t, map[string]string{"readme.txt": "no game"}), []byte("interrupted zip")} {
		u := newUpdater(t.TempDir(), Config{Schema: 1})
		installFixture(t, u, "0.1.1")
		file := filepath.Join(t.TempDir(), "bad.zip")
		os.WriteFile(file, data, 0600)
		if err := u.installArchive(file, manifestFor(data, "0.1.2", "https://example.com/game.zip")); err == nil {
			t.Fatal("broken archive accepted")
		}
		state, _ := u.current()
		if state.Version != "0.1.1" {
			t.Fatal(state)
		}
	}
}
func TestHTTPSAndLimits(t *testing.T) {
	u := newUpdater(t.TempDir(), Config{Schema: 1})
	for _, raw := range []string{"http://example.com/update.json", "file:///game.zip", "https://user:password@example.com/game.zip", "https://example.com/game.zip#fragment"} {
		if u.validateURL(raw) == nil {
			t.Fatal(raw)
		}
	}
	if u.validateURL("https://github.com/example/game/releases/latest/download/update.json") != nil {
		t.Fatal("valid GitHub URL rejected")
	}
	data := []byte("game")
	m := manifestFor(data, "0.1.1", "https://example.com/game.zip")
	m.Bytes = maxArchive + 1
	if validateManifest(m) == nil {
		t.Fatal("excessive download accepted")
	}
}
func TestLockReleasedAndExclusive(t *testing.T) {
	root := t.TempDir()
	unlock, err := acquireLock(root)
	if err != nil {
		t.Fatal(err)
	}
	if again, err := acquireLock(root); err == nil {
		again()
		t.Fatal("parallel launcher acquired lock")
	}
	unlock()
	unlock, err = acquireLock(root)
	if err != nil {
		t.Fatal("lock not released", err)
	}
	unlock()
}
func TestSymlinkRejected(t *testing.T) {
	var b bytes.Buffer
	z := zip.NewWriter(&b)
	h := &zip.FileHeader{Name: "Nocturne/link"}
	h.SetMode(os.ModeSymlink | 0777)
	w, _ := z.CreateHeader(h)
	io.WriteString(w, "../../outside")
	w, _ = z.Create(entrypoint)
	io.WriteString(w, "game")
	z.Close()
	file := filepath.Join(t.TempDir(), "bad.zip")
	os.WriteFile(file, b.Bytes(), 0600)
	if err := extractArchive(file, t.TempDir()); err == nil {
		t.Fatal("symlink accepted")
	}
}
