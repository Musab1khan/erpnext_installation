#!/bin/bash

# ERPNext Toolkit Setup Script
# Automatically makes doctor.sh and install-hybrid.sh executable
# اس اسکرپٹ کو چلانے سے ڈاکٹر اور انسٹالر اسکرپٹس ایکزیکیوٹ ہو جائیں گے

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   ERPNext Toolkit Setup / ٹول کٹ سیٹ اپ            ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "${YELLOW}Working directory: ${SCRIPT_DIR}${NC}"
echo -e "${YELLOW}کام کی ڈائریکٹری: ${SCRIPT_DIR}${NC}\n"

# Files to make executable
FILES=("doctor.sh" "install-hybrid.sh" "uninstall.sh")

SUCCESS_COUNT=0
ERROR_COUNT=0

for FILE in "${FILES[@]}"; do
    FILE_PATH="${SCRIPT_DIR}/${FILE}"

    if [ -f "$FILE_PATH" ]; then
        echo -e "${YELLOW}Processing / پروسیسنگ: ${FILE}${NC}"

        # Make the file executable
        if chmod +x "$FILE_PATH"; then
            echo -e "${GREEN}✓ Successfully made ${FILE} executable${NC}"
            echo -e "${GREEN}✓ ${FILE} کو ایکزیکیوٹ کر دیا گیا${NC}\n"
            ((SUCCESS_COUNT++))
        else
            echo -e "${RED}✗ Failed to make ${FILE} executable${NC}"
            echo -e "${RED}✗ ${FILE} کو ایکزیکیوٹ نہیں کیا جا سکا${NC}\n"
            ((ERROR_COUNT++))
        fi
    else
        echo -e "${RED}✗ File not found: ${FILE}${NC}"
        echo -e "${RED}✗ فائل نہیں ملی: ${FILE}${NC}\n"
        ((ERROR_COUNT++))
    fi
done

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Setup Summary / سیٹ اپ کا خلاصہ                    ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Success: ${SUCCESS_COUNT} files / کامیابی: ${SUCCESS_COUNT} فائلیں${NC}"

if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "${RED}✗ Errors: ${ERROR_COUNT} / غلطیاں: ${ERROR_COUNT}${NC}"
fi

echo ""

if [ $SUCCESS_COUNT -eq ${#FILES[@]} ]; then
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   All scripts are ready to use!                      ${NC}"
    echo -e "${GREEN}   تمام اسکرپٹس استعمال کے لیے تیار ہیں!             ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}\n"

    echo -e "${YELLOW}Usage / استعمال:${NC}"
    echo -e "  ${BLUE}./install-hybrid.sh${NC}  - Install ERPNext / ERPNext انسٹال کریں"
    echo -e "  ${BLUE}./doctor.sh${NC}          - Diagnose & fix all errors / غلطیاں تلاش کریں اور ٹھیک کریں"
    echo -e "  ${BLUE}./uninstall.sh${NC}       - Remove everything / سب کچھ ہٹا دیں\n"

    exit 0
else
    echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
    echo -e "${RED}   Setup completed with errors                         ${NC}"
    echo -e "${RED}   سیٹ اپ غلطیوں کے ساتھ مکمل ہوا                     ${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════${NC}\n"

    exit 1
fi
