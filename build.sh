#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="gotenberg-converter"
PORT="1971"
OUTPUT_DIR="pdfs"

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
    exit 0
}

# Set up trap to cleanup on exit or interrupt
trap cleanup EXIT INT TERM

echo -e "${BLUE}Starting DOCX to PDF conversion...${NC}"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Check if curl is available
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}Error: curl is required but not installed${NC}"
    exit 1
fi

# Find DOCX files in the root directory
docx_files=(*.docx)
if [[ ${#docx_files[@]} -eq 1 && ! -f "${docx_files[0]}" ]]; then
    echo -e "${YELLOW}No DOCX files found in the current directory${NC}"
    exit 0
fi

echo -e "${BLUE}Found ${#docx_files[@]} DOCX file(s) to convert${NC}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Start Gotenberg container
echo -e "${BLUE}Starting Gotenberg container...${NC}"
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "$PORT:3000" \
    gotenberg/gotenberg:8 \
    gotenberg --api-timeout=30s

# Wait for container to be ready
echo -e "${BLUE}Waiting for Gotenberg to be ready...${NC}"
for i in {1..30}; do
    if curl -s "http://localhost:$PORT/health" >/dev/null 2>&1; then
        echo -e "${GREEN}Gotenberg is ready!${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Error: Gotenberg failed to start${NC}"
        exit 1
    fi
    sleep 1
done

# Convert each DOCX file
for docx_file in "${docx_files[@]}"; do
    if [[ -f "$docx_file" ]]; then
        # Extract filename without extension
        filename=$(basename "$docx_file" .docx)
        output_file="$OUTPUT_DIR/${filename}.pdf"
        
        echo -e "${BLUE}Converting: $docx_file${NC}"
        
        # Convert using Gotenberg API
        if curl -s \
            --request POST \
            --url "http://localhost:$PORT/forms/libreoffice/convert" \
            --header 'Content-Type: multipart/form-data' \
            --form "files=@\"$docx_file\"" \
            --output "$output_file"; then
            echo -e "${GREEN}✓ Berg'd: $output_file${NC}"
        else
            echo -e "${RED}✗ Failed to convert: $docx_file${NC}"
        fi
    fi
done

echo -e "${GREEN}Conversion complete! PDFs saved in $OUTPUT_DIR/${NC}"

# Generate checksums for DOCX files
echo -e "${BLUE}Generating DOCX checksums...${NC}"
md5sum *.docx > .docx-checksums
echo -e "${GREEN}✓ Checksums saved to .docx-checksums${NC}"
