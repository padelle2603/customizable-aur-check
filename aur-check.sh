#!/bin/bash

# Configuration - Array containing all updated raw lists
URLS=(
    "https://md.archlinux.org/s/SxbqukK6IA/download"
    "https://cscs.pastes.sh/raw/aurvulnlist20260611.txt"
    "https://gist.githubusercontent.com/quantenProjects/3f768dce7331618310f016d975bf8547/raw/beef579f8a8efeed6ccf60788e5b768775550095/packages"
)

TEMP_FILE=$(mktemp)
TEMP_MERGE=$(mktemp)

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}[*] Fetching and merging compromised package lists...${NC}"

completed_sources=0

# Download from each source, clean up, and merge into the temporary file
for url in "${URLS[@]}"; do
    # Extract only the domain part to display clean output
    domain=$(echo "$url" | awk -F/ '{print $3}')

    if curl -fsS --proto '=https' --connect-timeout 10 "$url" | grep -v '^#' | tr -s '[:space:]' '\n' | sed 's/[*`_]//g' | grep -E '^[a-zA-Z0-9_-]+$' >> "$TEMP_MERGE" 2>/dev/null; then
        echo -e "  ${GREEN}[✓] Successfully downloaded from:${NC} $domain"
        ((completed_sources++))
    else
        echo -e "  ${RED}[!] Error or timeout downloading from:${NC} $domain"
    fi
done

# Check if at least one source was downloaded successfully
if [ "$completed_sources" -eq 0 ]; then
    echo -e "${RED}[!] Critical error: Unable to download any list of compromised packages.${NC}"
    rm -f "$TEMP_FILE" "$TEMP_MERGE"
    exit 1
fi

# Remove duplicates and sort the final list
sort -u "$TEMP_MERGE" > "$TEMP_FILE"
rm -f "$TEMP_MERGE"

# Check if the final unified temporary list is empty
if [ ! -s "$TEMP_FILE" ]; then
    echo -e "${RED}[!] The final unified list is empty or invalid.${NC}"
    rm -f "$TEMP_FILE"
    exit 1
fi

total_list=$(wc -l < "$TEMP_FILE")
echo -e "${GREEN}[+] Unified database ready (${total_list} unique tracked packages).${NC}"
echo -e "${YELLOW}[*] Checking installed AUR packages on the system...${NC}"

# Get "foreign" packages installed locally (i.e. installed from AUR)
# -Qm returns only packages not found in official repos
local_aur_map=$(pacman -Qm | awk '{print $1}')

if [ -z "$local_aur_map" ]; then
    echo -e "${GREEN}[+] No AUR packages installed on the system.${NC}"
    rm -f "$TEMP_FILE"
    exit 0
fi

# Counter for matches found
corrupted_found=0

# Loop through local AUR packages and check for matches with the compromised list
while read -r package; do
    if grep -qFx "$package" "$TEMP_FILE"; then
        echo -e "${RED}[!!!] WARNING: Installed package '$package' is present in the compromised lists!${NC}"
        ((corrupted_found++))
    fi
done <<< "$local_aur_map"

# Clean up temporary file
rm -f "$TEMP_FILE"

# Final result
if [ "$corrupted_found" -eq 0 ]; then
    echo -e "${GREEN}[+] Check completed successfully. No installed AUR package appears to be compromised.${NC}"
    exit 0
else
    echo -e "\n${RED}[!] WARNING: Found $corrupted_found potentially compromised packages on your system!${NC}"
    echo -e "${YELLOW}[i] We recommend removing them immediately using: pacman -Rns <package_name>${NC}"
    exit 2
fi
