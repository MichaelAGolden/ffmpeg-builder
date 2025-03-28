#!/bin/bash
set -eo pipefail # Exit on error, handle pipeline errors

# Default values
TIMESTAMP="template-config_$(date +%Y%m%dT%H%M%S)"
BUILD_ALL=true
BUILD_ARCH_TYPE1=false
BUILD_ARCH_TYPE2=false
OUTPUT_DIR="build/${TIMESTAMP}"
ARCHIVE_DIR="build/archive/${TIMESTAMP}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch_type1-only)
      BUILD_ALL=false
      BUILD_ARCH_TYPE1=true
      shift
      ;;
    --arch_type2-only)
      BUILD_ALL=false
      BUILD_ARCH_TYPE2=true
      shift
      ;;
    --timestamp)
      TIMESTAMP="$2"
      OUTPUT_DIR="build/${TIMESTAMP}"
      ARCHIVE_DIR="build/archive/${TIMESTAMP}"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --amd64-only    Build only AMD64 architecture"
      echo "  --arm64-only    Build only ARM64 architecture"
      echo "  --timestamp     Custom timestamp for build naming (default: current date/time)"
      echo "  --help          Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help to see available options"
      exit 1
      ;;
  esac
done

# Set which architectures to build
if [ "$BUILD_ALL" = true ]; then
  BUILD_AMD64=true
  BUILD_ARM64=true
fi

# Create output directories
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${ARCHIVE_DIR}"
echo "Output directories created under ${OUTPUT_DIR}"

# Build ARCH_TYPE1 if enabled
if [ "$BUILD_ARCH_TYPE1" = true ]; then
  echo "=== Starting ARCH_TYPE1 build ==="
  ./configs/template-config/arch_type1/build.sh --timestamp "${TIMESTAMP}" --output-dir "${OUTPUT_DIR}"
  echo "=== ARCH_TYPE1 build completed ==="
fi

# Build ARCH_TYPE2 if enabled
if [ "$BUILD_ARCH_TYPE2" = true ]; then
  echo "=== Starting ARCH_TYPE2 build ==="
  ./configs/template-config/arch_type2/build.sh --timestamp "${TIMESTAMP}" --output-dir "${OUTPUT_DIR}"
  echo "=== ARCH_TYPE2 build completed ==="
fi

# Create combined deployment package if both architectures were built
if [ "$BUILD_AMD64" = true ] && [ "$BUILD_ARM64" = true ]; then
  echo "=== Creating combined deployment package ==="
  ZIP_NAME="template-config_${TIMESTAMP}.zip"
  ABS_ZIP_PATH="$(pwd)/${ARCHIVE_DIR}/${ZIP_NAME}"
  
  if (cd "${OUTPUT_DIR}" && zip -qr "${ABS_ZIP_PATH}" .); then
    echo "Combined deployment package created: ${ARCHIVE_DIR}/${ZIP_NAME}"
    ls -lh "${ABS_ZIP_PATH}"
  else
    echo "Failed to create combined zip file."
    exit 1
  fi
fi

echo "=== Build process completed successfully! ==="
echo "All build artifacts available at: ${OUTPUT_DIR}"
echo "Archive files available at: ${ARCHIVE_DIR}" 
