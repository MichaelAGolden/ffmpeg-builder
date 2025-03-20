#!/bin/bash

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get current timestamp for build identification
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BUILD_DIR="build/${TIMESTAMP}"
ARCHIVE_DIR="build/archive/${TIMESTAMP}"

# Create directory structure
mkdir -p ${BUILD_DIR}/{arm64,x86_64}/bin
mkdir -p ${ARCHIVE_DIR}

build_for_architecture() {
    local arch=$1
    local dockerfile=$2
    local output_dir=$3
    local zip_name=$4
    
    echo -e "${YELLOW}Building FFmpeg for ${arch}...${NC}"
    
    # Build the Docker image
    echo -e "${YELLOW}Building Docker image for ${arch}...${NC}"
    docker build -t ffmpeg-${arch}-builder -f ${dockerfile} .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to build Docker image for ${arch}.${NC}"
        return 1
    fi
    
    # Extract binaries directly from the container
    echo -e "${YELLOW}Extracting FFmpeg binaries from container...${NC}"
    container_id=$(docker create ffmpeg-${arch}-builder)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create container from the image for ${arch}.${NC}"
        return 1
    fi
    
    # Save the build logs
    docker logs $container_id > ${output_dir}/build.log 2>&1
    
    # Copy the binaries out of the container
    docker cp $container_id:/ffmpeg_build/bin/ffmpeg ${output_dir}/bin/
    docker cp $container_id:/ffmpeg_build/bin/ffprobe ${output_dir}/bin/
    
    # Remove the container
    docker rm $container_id > /dev/null
    
    # Make binaries executable
    chmod +x ${output_dir}/bin/ffmpeg ${output_dir}/bin/ffprobe
    
    echo -e "${GREEN}Extraction complete for ${arch}!${NC}"
    echo -e "${GREEN}FFmpeg binaries are available in the ${output_dir}/bin directory${NC}"
    echo -e "${YELLOW}Binaries for ${arch}:${NC}"
    ls -lh ${output_dir}/bin/
    
    # Create deployment package
    echo -e "\n${YELLOW}Creating deployment package for ${arch}...${NC}"
    
    # Include timestamp in the filename
    zip_name_with_timestamp=$(echo $zip_name | sed "s/.zip/_${TIMESTAMP}.zip/")
    zip_path_with_timestamp="${ARCHIVE_DIR}/${zip_name_with_timestamp}"
    
    # Create a symbolic link for the latest version
    ln -sf "${zip_name_with_timestamp}" "${ARCHIVE_DIR}/${zip_name}"
    
    # Create zip file
    cd ${output_dir}
    zip -r "${OLDPWD}/${zip_path_with_timestamp}" bin/
    cd - > /dev/null
    
    echo -e "${GREEN}Deployment package created: ${zip_name_with_timestamp}${NC}"
    echo -e "${GREEN}Package location: ${zip_path_with_timestamp}${NC}"
    ls -lh "${zip_path_with_timestamp}"
    
    # Record file info for reference
    echo -e "Build completed at: $(date)" > "${output_dir}/build_info.txt"
    echo -e "Architecture: ${arch}" >> "${output_dir}/build_info.txt"
    echo -e "Dockerfile: ${dockerfile}" >> "${output_dir}/build_info.txt"
    echo -e "Binary sizes:" >> "${output_dir}/build_info.txt"
    ls -lh ${output_dir}/bin/ >> "${output_dir}/build_info.txt"
    echo -e "Zip package: ${zip_path_with_timestamp}" >> "${output_dir}/build_info.txt"
    
    return 0
}

# Main script

echo -e "${YELLOW}Building FFmpeg for multiple architectures...${NC}"
echo -e "${YELLOW}Build ID: ${TIMESTAMP}${NC}"
echo -e "${YELLOW}All outputs will be in ${BUILD_DIR} and ${ARCHIVE_DIR}${NC}"

# Build for ARM64 (Amazon lambda/provided:al2023)
build_for_architecture "arm64-lambda-provided-al2023" "Dockerfile.arm64" "${BUILD_DIR}/arm64" "ffmpeg-arm64.zip"

# Build for x86_64 (Amazon lambda/provided:al2023)
build_for_architecture "x86_64-lambda-provided-al2023" "Dockerfile.x86_64" "${BUILD_DIR}/x86_64" "ffmpeg-x86_64.zip"

# Write a build summary
echo -e "${YELLOW}Creating build summary...${NC}"
cat > "${BUILD_DIR}/summary.txt" << EOF
FFmpeg Build Summary
===================
Build ID: ${TIMESTAMP}
Date: $(date)

This build includes:
- ARM64 binaries for Amazon lambda/provided:al2023
- x86_64 binaries for Amazon lambda/provided:al2023

Archives:
- ${ARCHIVE_DIR}/ffmpeg-arm64_${TIMESTAMP}.zip
- ${ARCHIVE_DIR}/ffmpeg-x86_64_${TIMESTAMP}.zip

Build logs and binaries are stored in subdirectories.
EOF

# Copy the summary to the archive directory too
cp "${BUILD_DIR}/summary.txt" "${ARCHIVE_DIR}/"

# Create a latest.txt file that contains the current build timestamp
echo "${TIMESTAMP}" > "build/latest.txt"

echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}Build outputs stored in: ${BUILD_DIR}${NC}"
echo -e "${GREEN}Archives stored in: ${ARCHIVE_DIR}${NC}"

# In GitHub Actions environment, we don't need to prompt for cleanup
if [ -z "$GITHUB_ACTIONS" ]; then
    # Prompt to clean up the Docker images when running locally
    echo -e "\n${YELLOW}Do you want to remove the Docker build images to save space? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        docker rmi ffmpeg-arm64-lambda-builder ffmpeg-x86_64-lambda-builder
        echo -e "${GREEN}Docker images removed.${NC}"
    fi
    
    echo -e "\n${YELLOW}Use these packages with your application:${NC}"
    echo -e "1. Extract the appropriate package from the build/archive directory"
    echo -e "2. For AWS Lambda, include the binaries in your deployment package"
    echo -e "3. Call ffmpeg from your code using /var/task/bin/ffmpeg (Lambda) or the appropriate path"
    echo -e "4. All archives are stored in ${ARCHIVE_DIR}"
else
    # In GitHub Actions, always clean up
    docker rmi ffmpeg-arm64-lambda-builder ffmpeg-x86_64-lambda-builder
    echo -e "${GREEN}Docker images removed.${NC}"
fi
