package main

import (
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
)

const launcherVersion = "1.0.0"

func main() {
	if err := run(os.Args[1:]); err != nil {
		quiet := false
		for _, arg := range os.Args[1:] {
			if arg == "--quiet" {
				quiet = true
			}
		}
		if quiet {
			fmt.Fprintln(os.Stderr, err)
		} else {
			showMessage("Nocturne", err.Error(), true)
		}
		os.Exit(1)
	}
}
func run(args []string) error {
	executable, err := os.Executable()
	if err != nil {
		return err
	}
	executable, err = filepath.Abs(executable)
	if err != nil {
		return err
	}
	source := filepath.Dir(executable)
	root, err := installationRoot()
	if err != nil {
		return err
	}
	if err = os.MkdirAll(root, 0700); err != nil {
		return err
	}
	unlock, err := acquireLock(root)
	if err != nil {
		return err
	}
	defer unlock()
	logFile, err := os.OpenFile(filepath.Join(root, "launcher.log"), os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0600)
	if err == nil {
		defer logFile.Close()
		log.SetOutput(logFile)
	}
	log.Printf("Launcher %s", launcherVersion)
	var cfg Config
	if err = readJSON(filepath.Join(root, "launcher.json"), &cfg); err != nil {
		if err = readJSON(filepath.Join(source, "launcher.json"), &cfg); err != nil {
			return errors.New("Launcher configuration is missing. Extract the complete setup ZIP, then run Install-Nocturne.cmd.")
		}
	}
	updater := newUpdater(root, cfg)
	install, offline, rollback, quiet := false, false, false, false
	for _, arg := range args {
		switch arg {
		case "--install":
			install = true
		case "--offline":
			offline = true
		case "--rollback":
			rollback = true
		case "--quiet":
			quiet = true
		default:
			return fmt.Errorf("unknown launcher option: %s", arg)
		}
	}
	if install {
		// Read bundled config even when updating an existing launcher installation.
		if err = readJSON(filepath.Join(source, "launcher.json"), &cfg); err != nil {
			return err
		}
		if cfg.Schema != 1 {
			return errors.New("unsupported launcher configuration")
		}
		if err = updater.validateURL(cfg.ManifestURL); err != nil {
			return err
		}
		updater.Config = cfg
		if err = copyFile(executable, filepath.Join(root, "Nocturne-Launcher.exe")); err != nil {
			return err
		}
		if err = writeJSON(filepath.Join(root, "launcher.json"), cfg); err != nil {
			return err
		}
		var bundled Manifest
		if err = readJSON(filepath.Join(source, "payload", "update.json"), &bundled); err != nil {
			return err
		}
		current, currentErr := updater.current()
		if currentErr != nil || newer(bundled.Version, current.Version) {
			if err = updater.installArchive(filepath.Join(source, "payload", "Nocturne-Windows.zip"), bundled); err != nil {
				return err
			}
		}
		if err = createShortcut(root); err != nil {
			return err
		}
		if !quiet {
			showMessage("Nocturne installed", "A Nocturne shortcut has been added to your desktop. Open it to play. Future tested updates download automatically when you launch the game. Your existing case saves are preserved.", false)
		}
		return nil
	}
	if rollback {
		if err = updater.rollback(); err != nil {
			return err
		}
		offline = true
	}
	if !offline {
		fmt.Println("Nocturne: checking for updates...")
		if updated, updateErr := updater.checkForUpdate(); updateErr != nil {
			log.Printf("Update unavailable; retaining installed game: %v", updateErr)
		} else if updated {
			log.Print("New game version installed")
		}
	}
	if _, err = updater.current(); err != nil {
		return errors.New("No installed game is available. Extract the setup ZIP and run Install-Nocturne.cmd.")
	}
	fmt.Println("Starting Nocturne...")
	hideConsole()
	return updater.runGame()
}
func copyFile(source, target string) error {
	sourceAbs, _ := filepath.Abs(source)
	targetAbs, _ := filepath.Abs(target)
	if strings.EqualFold(sourceAbs, targetAbs) {
		return nil
	}
	in, err := os.Open(source)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.CreateTemp(filepath.Dir(target), ".launcher-*.tmp")
	if err != nil {
		return err
	}
	name := out.Name()
	defer os.Remove(name)
	_, copyErr := io.Copy(out, in)
	closeErr := out.Close()
	if copyErr != nil {
		return copyErr
	}
	if closeErr != nil {
		return closeErr
	}
	return os.Rename(name, target)
}
