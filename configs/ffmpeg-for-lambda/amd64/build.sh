#!/bin/bash
set -eo pipefail # Exit on error, handle pipeline errors

# Define architecture and paths
ARCH="amd64"
CONFIG_DIR="."
DOCKERFILE="${CONFIG_DIR}/Dockerfile.amd64"

# Default settings
TIMESTAMP="local_$(date +%Y%m%dT%H%M%S)"
OUTPUT_DIR="build/${TIMESTAMP}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --timestamp)
      TIMESTAMP="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Define output directories
BUILD_BIN_DIR="${OUTPUT_DIR}/${ARCH}/bin"
ARCHIVE_DIR="build/archive/${TIMESTAMP}"
IMAGE_TAG="ffmpeg-${ARCH}-builder:${TIMESTAMP}"

echo "--- Creating local output directories ---"
mkdir -p "${BUILD_BIN_DIR}"
mkdir -p "${ARCHIVE_DIR}"
echo "Output directories created under ${OUTPUT_DIR}"

echo "--- Building Docker image for ${ARCH} (Target: linux/amd64) ---"
docker buildx build --platform linux/${ARCH} \
  --progress=plain \
  -t "${IMAGE_TAG}" \
  -f "${DOCKERFILE}" \
  "${CONFIG_DIR}" --load
echo "Docker image built successfully: ${IMAGE_TAG}"

echo "--- Extracting FFmpeg binaries from image ---"
container_id=$(docker create "${IMAGE_TAG}")

if [ -z "$container_id" ]; then
  echo "Failed to create container from image ${IMAGE_TAG}"
  exit 1
fi
echo "Temporary container created: ${container_id}"

docker cp "${container_id}:/ffmpeg_build/bin/ffmpeg" "${BUILD_BIN_DIR}/"
docker cp "${container_id}:/ffmpeg_build/bin/ffprobe" "${BUILD_BIN_DIR}/"

docker rm "${container_id}" > /dev/null 2>&1 || echo "Warning: Could not remove container ${container_id}"

chmod +x "${BUILD_BIN_DIR}/ffmpeg" "${BUILD_BIN_DIR}/ffprobe"

echo "Extraction complete!"
echo "Binaries are available in: ${BUILD_BIN_DIR}"
ls -lh "${BUILD_BIN_DIR}"

echo "--- Creating deployment package ---"
ZIP_NAME="ffmpeg-${ARCH}.zip"
zip_name_with_timestamp="${ZIP_NAME/.zip/_${TIMESTAMP}.zip}"
zip_path_with_timestamp="${ARCHIVE_DIR}/${zip_name_with_timestamp}"
abs_zip_path_with_timestamp="$(pwd)/${zip_path_with_timestamp}"

if (cd "${OUTPUT_DIR}/${ARCH}" && zip -qr "${abs_zip_path_with_timestamp}" bin/); then
    echo "Deployment package created: ${zip_path_with_timestamp}"
    ls -lh "${abs_zip_path_with_timestamp}"
else
    echo "Failed to create zip file."
    exit 1
fi

echo "--- Cleaning up Docker image ---"
docker rmi "${IMAGE_TAG}" > /dev/null 2>&1 || echo "Warning: Could not remove image ${IMAGE_TAG}"
echo "Image removed."

echo "--- ${ARCH} build completed successfully! ---"
