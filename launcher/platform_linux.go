//go:build linux

package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"syscall"
)

func installationRoot() (string, error) {
	root, err := os.UserCacheDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(root, "Nocturne"), nil
}
func acquireLock(root string) (func(), error) {
	f, err := os.OpenFile(filepath.Join(root, "launcher.lock"), os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return nil, err
	}
	if err = syscall.Flock(int(f.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		f.Close()
		return nil, errors.New("Nocturne is already running or updating")
	}
	return func() { syscall.Flock(int(f.Fd()), syscall.LOCK_UN); f.Close() }, nil
}
func showMessage(title, text string, failure bool) { fmt.Fprintln(os.Stderr, title+": "+text) }
func createShortcut(root string) error {
	return errors.New("desktop installation targets Windows; Linux is used for updater tests")
}

func hideConsole() {}
