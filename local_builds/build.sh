#!/bin/sh
set -eo pipefail # Exit on error, treat pipeline failures as errors
# Define architecture and paths
export ARCH="arm64"
export CONFIG_DIR="configs/ffmpeg-for-lambda"
export DOCKERFILE="${CONFIG_DIR}/Dockerfile.arm64"

# Define a timestamp for output folders (similar to GHA)
export TIMESTAMP="local_$(date +%Y%m%d_%H%M%S)"

# Define output directories
export BUILD_BIN_DIR="build/${TIMESTAMP}/${ARCH}/bin"
export BUILD_LOG_DIR="build/${TIMESTAMP}/${ARCH}"
export ARCHIVE_DIR="build/archive/${TIMESTAMP}"

# Define the image tag for this build
export IMAGE_TAG="ffmpeg-${ARCH}-builder:${TIMESTAMP}"

echo "Creating local output directories..."
mkdir -p "${BUILD_BIN_DIR}"
mkdir -p "${ARCHIVE_DIR}"
echo "Output directories created under build/${TIMESTAMP}"

echo "Building Docker image for ${ARCH} (Target: linux/arm64)..."
docker buildx build --platform linux/${ARCH} \
  -t "${IMAGE_TAG}" \
  -f "${DOCKERFILE}" \
  "${CONFIG_DIR}" --load

# Check if build succeeded (optional)
if [ $? -ne 0 ]; then
  echo "Docker build failed!"
  exit 1
fi
echo "Docker image built successfully: ${IMAGE_TAG}"

echo "Extracting FFmpeg binaries from image..."
# Create a temporary container from the built image
container_id=$(docker create "${IMAGE_TAG}")

if [ -z "$container_id" ]; then
  echo "Failed to create container from image ${IMAGE_TAG}"
  exit 1
fi

echo "Temporary container created: ${container_id}"

# Copy the binaries from the container to your local directory
docker cp "${container_id}:/ffmpeg_build/bin/ffmpeg" "${BUILD_BIN_DIR}/"
docker cp "${container_id}:/ffmpeg_build/bin/ffprobe" "${BUILD_BIN_DIR}/"

# Clean up (remove) the temporary container
docker rm "${container_id}" > /dev/null

# Make the extracted binaries executable
chmod +x "${BUILD_BIN_DIR}/ffmpeg" "${BUILD_BIN_DIR}/ffprobe"

echo "Extraction complete!"
echo "Binaries are available in: ${BUILD_BIN_DIR}"
ls -lh "${BUILD_BIN_DIR}"

echo "Creating deployment package..."
export ZIP_NAME="ffmpeg-${ARCH}.zip" # Base name from GHA
export zip_name_with_timestamp="${ZIP_NAME/.zip/_${TIMESTAMP}.zip}"
export zip_path_with_timestamp="${ARCHIVE_DIR}/${zip_name_with_timestamp}"

# Go into the directory containing 'bin' to zip it correctly
(cd "build/${TIMESTAMP}/${ARCH}" && zip -r "${PWD}/${zip_path_with_timestamp}" bin/)


# Go into the directory containing 'bin' to zip it correctly
# Use the absolute path for the output zip file
if (cd "build/${TIMESTAMP}/${ARCH}" && zip -qr "${abs_zip_path_with_timestamp}" bin/); then
    echo "Deployment package created: ${zip_path_with_timestamp}" # Still show relative path
    ls -lh "${abs_zip_path_with_timestamp}"
else
    echo "Failed to create zip file."
    # Consider exiting if zip fails and it's critical
    # exit 1
fi

echo "Cleaning up Docker image ${IMAGE_TAG}..."
docker rmi "${IMAGE_TAG}"
echo "Image removed."
