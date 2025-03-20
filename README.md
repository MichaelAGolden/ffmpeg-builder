# FFmpeg Builder Template

This repository provides a template for creating Docker-based build pipelines for FFmpeg binaries. It includes a complete example for building minimal, optimized FFmpeg binaries tailored for AWS Lambda using Amazon Linux 2023 runtime images.

## Important Notes

This repository **does not distribute pre-built binaries** to comply with licensing restrictions. Instead, it provides a template system for you to build your own binaries with configurations tailored to your specific needs.

See the [FFmpeg License](https://ffmpeg.org/legal.html) for licensing details.

## Template System Overview

This template repository is designed to make it easy to build custom FFmpeg binaries for different environments and use cases. It's structured as follows:

- **Configuration Directories**: Each build configuration has its own directory in the `configs/` folder
- **GitHub Workflows**: Build workflows that can build any configuration in the configs directory
- **Template Files**: Sample templates to help you create your own configurations

### Available Configurations

- **[ffmpeg-for-lambda](configs/ffmpeg-for-lambda/)**: A minimal, optimized FFmpeg build for AWS Lambda focused on audio processing

### Creating Your Own Configuration

1. Create a new directory in the `configs/` folder (e.g., `configs/my-custom-config/`)
2. Copy and modify the template files from `configs/template-config/`
3. Customize the Dockerfile and readme.md to suit your needs
4. Run the build workflow specifying your custom configuration

## Features

- **Configuration Templates**: Easy-to-use templates for creating custom FFmpeg builds
- **GitHub Actions Integration**: Automated workflows for building all configurations
- **Modular Design**: Each configuration is self-contained and can be built independently
- **Comprehensive Documentation**: Detailed readmes for each configuration

## How to Use This Template Repository

### Option 1: Create Your Own Repository from This Template

1. Click the "Use this template" button at the top of this GitHub repository
2. Create a new repository (public or private) based on this template
3. Clone your new repository and customize it for your needs
4. Run the GitHub Actions workflows to build your custom FFmpeg binaries

### Option 2: Fork and Customize

1. Fork this repository
2. Customize the existing configurations or add your own
3. Run the GitHub Actions workflows to build your custom FFmpeg binaries

### Option 3: Local Docker Builds

To build the FFmpeg binaries locally:

```bash
# Clone repo
git clone https://github.com/yourusername/ffmpeg-builder.git
cd ffmpeg-builder

# Build a specific configuration
docker build -t ffmpeg-arm64-builder -f configs/ffmpeg-for-lambda/Dockerfile.arm64 configs/ffmpeg-for-lambda

# Extract the binaries
mkdir -p output
container_id=$(docker create ffmpeg-arm64-builder)
docker cp $container_id:/ffmpeg_build/bin/ffmpeg output/
docker cp $container_id:/ffmpeg_build/bin/ffprobe output/
docker rm $container_id
```

## Repository Structure

The repository is organized to make it easy to maintain multiple build configurations:

- `.github/workflows/` - Contains GitHub Action workflow files for automated builds:
  - `build-all.yml` - Builds for all architectures in a specific configuration
  - `build-al2023-arm64.yml` - Dedicated workflow for ARM64
  - `build-al2023-x86_64.yml` - Dedicated workflow for x86_64
- `configs/` - Contains different build configurations:
  - `ffmpeg-for-lambda/` - Configuration for AWS Lambda
  - `template-config/` - Template files for creating new configurations

Each configuration directory includes:

- `Dockerfile.arm64` - Dockerfile for ARM64 builds
- `Dockerfile.x86_64` - Dockerfile for x86_64 builds
- `readme.md` - Documentation specific to that configuration

## Creating a New Configuration

To create a new configuration:

1. Create a new directory in the `configs/` folder
2. Copy the template files from `configs/template-config/`
3. Modify the Dockerfile and readme.md to suit your needs
4. Run the build workflow with your new configuration

```bash
# Create a new configuration
mkdir -p configs/my-custom-config
cp configs/template-config/* configs/my-custom-config/
# Edit the files as needed
```

To add your configuration to the build system:

1. Update the matrix configuration in `.github/workflows/build-all.yml`
2. Create a dedicated workflow file if needed (optional)

## License

This project and it's template repository is MIT licensed as it just provides a build pipeline and does not distribute any FFmpeg binaries directly.

However, the resulting binaries from this build process may include components under GPL and other licenses. Please refer to the [FFmpeg License](https://ffmpeg.org/legal.html) for more details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request to add new configurations or improve existing ones.
