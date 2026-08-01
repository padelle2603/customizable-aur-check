
# AUR Compromised Package Checker

A simple Bash script to check locally installed Arch Linux (AUR) packages against multiple remote databases of compromised packages.

## Features

- Downloads and merges known compromised package lists from multiple HTTPS sources.
- Normalizes and sanitizes list entries (removes markdown formatting, spaces, and duplicates).
- Cross-references local foreign packages (`pacman -Qm`) against the unified threat database.
- Uses color-coded terminal output for quick visual auditing.

---

## Prerequisites

- **Arch Linux** (or any Arch-based distribution using `pacman`).
- System utilities: `bash`, `curl`, `awk`, `sed`, `grep`, `sort`, `pacman`.

---

## Installation & Usage

#### Standalone Binary / Executable Script

1. Download the script from the [Releases](../../releases) section (or clone the repository).
2. Make it executable and run it:

```bash
chmod +x aur-vulnerability-check.sh
./aur-vulnerability-check.sh

```

---

## Exit Codes

* `0`: Success (No compromised packages found, or no local AUR packages installed).
* `1`: Download or list parsing error.
* `2`: **Warning:** One or more installed AUR packages match the compromised database.

