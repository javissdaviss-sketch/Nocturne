//go:build windows

package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"unsafe"
)

func installationRoot() (string, error) {
	base := os.Getenv("LOCALAPPDATA")
	if base == "" {
		return "", errors.New("Windows LocalAppData folder is unavailable")
	}
	return filepath.Join(base, "Nocturne"), nil
}
func acquireLock(root string) (func(), error) {
	name, err := syscall.UTF16PtrFromString("Local\\NocturneLauncher-" + strings.ReplaceAll(root, `\`, "_"))
	if err != nil {
		return nil, err
	}
	kernel := syscall.NewLazyDLL("kernel32.dll")
	handle, _, callErr := kernel.NewProc("CreateMutexW").Call(0, 0, uintptr(unsafe.Pointer(name)))
	if handle == 0 {
		return nil, callErr
	}
	if callErr == syscall.Errno(183) {
		syscall.CloseHandle(syscall.Handle(handle))
		return nil, errors.New("Nocturne is already running or updating")
	}
	return func() { syscall.CloseHandle(syscall.Handle(handle)) }, nil
}
func showMessage(title, text string, failure bool) {
	t, _ := syscall.UTF16PtrFromString(title)
	body, _ := syscall.UTF16PtrFromString(text)
	flags := uintptr(0x40)
	if failure {
		flags = 0x10
	}
	syscall.NewLazyDLL("user32.dll").NewProc("MessageBoxW").Call(0, uintptr(unsafe.Pointer(body)), uintptr(unsafe.Pointer(t)), flags)
}
func psQuote(s string) string { return "'" + strings.ReplaceAll(s, "'", "''") + "'" }
func createShortcut(root string) error {
	// Windows resolves the real Desktop location, including OneDrive redirection.
	// Use the system PowerShell executable; no global execution-policy changes.
	windows := os.Getenv("SystemRoot")
	if windows == "" {
		return errors.New("Windows system directory unavailable")
	}
	powershell := filepath.Join(windows, "System32", "WindowsPowerShell", "v1.0", "powershell.exe")
	script := "$ErrorActionPreference='Stop'; $desktop=[Environment]::GetFolderPath('Desktop','DoNotVerify'); if([string]::IsNullOrEmpty($desktop)){throw 'Desktop folder is unavailable'}; [IO.Directory]::CreateDirectory($desktop)|Out-Null; $shell=New-Object -ComObject WScript.Shell; $shortcut=$shell.CreateShortcut((Join-Path $desktop 'Nocturne.lnk')); $shortcut.TargetPath=" + psQuote(filepath.Join(root, "Nocturne-Launcher.exe")) + "; $shortcut.WorkingDirectory=" + psQuote(root) + "; $shortcut.Description='Play Nocturne and check for updates'; $shortcut.Save()"
	cmd := exec.Command(powershell, "-NoProfile", "-NonInteractive", "-Command", script)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("could not create desktop shortcut: %w (%s)", err, strings.TrimSpace(string(out)))
	}
	return nil
}

func hideConsole() {
	kernel := syscall.NewLazyDLL("kernel32.dll")
	var processes [2]uint32
	count, _, _ := kernel.NewProc("GetConsoleProcessList").Call(uintptr(unsafe.Pointer(&processes[0])), 2)
	if count != 1 {
		return
	}
	window, _, _ := kernel.NewProc("GetConsoleWindow").Call()
	if window != 0 {
		syscall.NewLazyDLL("user32.dll").NewProc("ShowWindow").Call(window, 0)
	}
}
