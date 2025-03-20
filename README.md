# FFmpeg Builder

This repository provides a Docker-based build pipeline for creating minimal, optimized FFmpeg binaries specifically tailored for AWS Lambda using the Amazon Linux 2023 Lambda runtime images (ARM64 and x86_64). It significantly reduces binary size and improves performance over pre-built alternatives. It's easily customizable for other environments and architectures.

## Important Notes

This repository **does not distribute pre-built binaries** to comply with licensing restrictions. To use the binaries, fork this repository and run the builds yourself.

See the [FFmpeg License](https://ffmpeg.org/legal.html) for licensing details.

## Features

- Automated builds using GitHub Actions
- Architecture support:
  - ARM64 for Amazon lambda/provided:al2023
  - x86_64 for Amazon lambda/provided:al2023-x86_64
- Small binary sizes (~3.6MB)
- Build process pulls from the [latest snapshot of FFmpeg](https://ffmpeg.org/releases/) and the [latest versions of the Amazon Lambda/Provided:AL2023 container images](https://gallery.ecr.aws/lambda/provided) to ensure compatibility at time of build between latest FFmpeg release and latest AmazonLinux 2023 provided lambda container image release.

## How to Use This Repository

### Option 1: Fork and Build via GitHub Actions

1. Fork this repository.
2. Enable GitHub Actions in your fork.
3. Run the workflow manually or schedule it.
4. Download binaries from the Actions tab in your fork.

### Option 2: Local Docker Builds

Ensure Docker is installed (tested on Mac with Apple Silicon).

## Building Locally

To build the FFmpeg binaries locally:

```bash
# Clone repo
git clone https://github.com/yourusername/ffmpeg-builder.git
cd ffmpeg-builder
# Run build script
./build-ffmpeg.sh
```

Note: You will need to have Docker installed to build the FFmpeg binaries locally. I have only tested this on a Mac running Apple Silicon, I cannot guarantee it will work on other platforms.

This will build FFmpeg for all supported architectures. If you want to build for a specific architecture, you can modify the script before running.

## Using in AWS Lambda

### Using the zip file deployment method

I'm learning as I go so this is a work in progress, but I will leave this note here for now regarding how to use the zip file deployment method instead of building your own container image. With the binary size so small for ffmpeg, the benefits of the zip file deployment method seem to significantly outweigh the benefits of building your own container image for ease of maintaining your own container image as the provided container images are regularly updated by AWS for security and bug fixes.

[Go on AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/golang-package.html)
[Node.js on AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/nodejs-package.html)

#### Steps

1. Download the zip file from the Actions tab in your forked repository
1. Extract the appropriate binaries to your Lambda deployment package:

   ```bash
   # For ARM64 Lambda
   unzip ffmpeg-arm64.zip -d your-lambda-project/

   # For x86_64 Lambda
   unzip ffmpeg-x86_64.zip -d your-lambda-project/
   ```

1. Below are examples of how to use the FFmpeg binaries in your Lambda function code for each supported languages. Refer to the [AWS Lambda Documentation on Runtimes](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html) on how to use the FFmpeg binaries in your Lambda function code.

   Note: The following examples are how to use the FFmpeg binary to create a clip from an audio file of some length.
   Both of the following commands will create a 5 second clip from the input.mp3 file starting at 25 seconds and ending at 30 seconds.

   ```bash
   ffmpeg -i input.mp3 -ss 25 -to 30 -c:a libmp3lame -qscale:a 2 output.mp3
   ```

   ```javascript
   const { spawnSync } = require("child_process");
   const path = require("path");

   exports.handler = async () => {
     const ffmpegPath = path.join(process.env.LAMBDA_TASK_ROOT, "bin/ffmpeg");

     const result = spawnSync(ffmpegPath, [
       "-i",
       "input.mp3",
       "-ss",
       "25",
       "-to",
       "30",
       "-c:a",
       "libmp3lame",
       "-qscale:a",
       "2",
       "/tmp/output.mp3",
     ]);

     console.log(result.stdout.toString());
     console.log(result.stderr.toString());

     return { statusCode: 200 };
   };
   ```

```go
// Go example
package main

import (
    "context"
    "fmt"
    "os/exec"

    "github.com/aws/aws-lambda-go/lambda"
)

func HandleRequest(ctx context.Context, event []byte) (string, error) {
    cmd := exec.Command("ffmpeg", "-i", "input.mp3", "-ss", "25", "-to", "30", "-c:a", "libmp3lame", "-qscale:a", "2", "output.mp3")
    return cmd.Run()
}

func main() {
    lambda.Start(HandleRequest)
}
```

## Customization

If you need to customize the FFmpeg build, modify the appropriate Dockerfile to add or remove:

- Libraries (e.g., adding libvpx, x264)
- Encoders/decoders
- Filters
- Other FFmpeg components

The project includes the following Dockerfiles:

- `Dockerfile.arm64` - For AWS Lambda ARM64 builds
- `Dockerfile.x86_64` - For AWS Lambda x86_64 builds

After modifying, commit the changes and run the GitHub Action workflow or build locally.

## License

This project is provided as a build pipeline and does not distribute any FFmpeg binaries directly. The resulting binaries from this build process may include components under GPL and other licenses. Please refer to the [FFmpeg License](https://ffmpeg.org/legal.html) for more details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
