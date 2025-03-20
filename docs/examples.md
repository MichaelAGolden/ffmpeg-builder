# FFmpeg Usage Examples

This document provides examples of how to use the minimized FFmpeg binaries in various environments.

## AWS Lambda (Node.js)

```javascript
const { spawnSync } = require("child_process");

exports.handler = async (event) => {
  // Path to the FFmpeg binary in your Lambda deployment package
  const ffmpegPath = process.env.LAMBDA_TASK_ROOT + "/bin/ffmpeg";

  // Example: Convert MP3 to AAC
  const result = spawnSync(ffmpegPath, [
    "-i",
    "/tmp/input.mp3",
    "-c:a",
    "aac",
    "-b:a",
    "128k",
    "/tmp/output.aac",
  ]);

  console.log("FFmpeg stdout:", result.stdout.toString());
  console.log("FFmpeg stderr:", result.stderr.toString());

  // Check if FFmpeg executed successfully
  if (result.status !== 0) {
    throw new Error(`FFmpeg exited with code ${result.status}`);
  }

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: "Audio conversion completed successfully",
    }),
  };
};
```

## AWS Lambda (Python)

```python
import subprocess
import os

def lambda_handler(event, context):
    # Path to the FFmpeg binary in your Lambda deployment package
    ffmpeg_path = os.path.join(os.environ['LAMBDA_TASK_ROOT'], 'bin', 'ffmpeg')

    # Example: Extract audio from video
    command = [
        ffmpeg_path,
        '-i', '/tmp/input.mp4',
        '-vn',
        '-acodec', 'libmp3lame',
        '-q:a', '2',
        '/tmp/output.mp3'
    ]

    # Run FFmpeg
    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    # Log FFmpeg output
    print(f"FFmpeg stdout: {result.stdout.decode('utf-8')}")
    print(f"FFmpeg stderr: {result.stderr.decode('utf-8')}")

    # Check if FFmpeg executed successfully
    if result.returncode != 0:
        raise Exception(f"FFmpeg exited with code {result.returncode}")

    return {
        'statusCode': 200,
        'body': 'Audio extraction completed successfully'
    }
```

## AWS Lambda with S3 (Node.js)

```javascript
const { spawnSync } = require("child_process");
const AWS = require("aws-sdk");
const fs = require("fs");
const path = require("path");

const s3 = new AWS.S3();

exports.handler = async (event) => {
  // Get information about the S3 object from the event
  const bucket = event.Records[0].s3.bucket.name;
  const key = decodeURIComponent(
    event.Records[0].s3.object.key.replace(/\+/g, " ")
  );

  // Set up input and output file paths
  const inputFile = "/tmp/input.mp3";
  const outputFile = "/tmp/output.mp3";

  // Download file from S3
  await s3
    .getObject({
      Bucket: bucket,
      Key: key,
    })
    .promise()
    .then((data) => {
      fs.writeFileSync(inputFile, data.Body);
    });

  // Path to the FFmpeg binary in your Lambda deployment package
  const ffmpegPath = process.env.LAMBDA_TASK_ROOT + "/bin/ffmpeg";

  // Example: Normalize audio volume
  const result = spawnSync(ffmpegPath, [
    "-i",
    inputFile,
    "-filter:a",
    "loudnorm",
    "-c:a",
    "libmp3lame",
    "-q:a",
    "2",
    outputFile,
  ]);

  // Check if FFmpeg executed successfully
  if (result.status !== 0) {
    throw new Error(`FFmpeg exited with code ${result.status}`);
  }

  // Upload processed file back to S3
  const outputKey = key.replace(/\.[^/.]+$/, "") + "_normalized.mp3";

  await s3
    .putObject({
      Bucket: bucket,
      Key: outputKey,
      Body: fs.readFileSync(outputFile),
      ContentType: "audio/mpeg",
    })
    .promise();

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: "Audio processing completed",
      outputFile: `s3://${bucket}/${outputKey}`,
    }),
  };
};
```

## Common FFmpeg Commands

Here are some useful command examples for the minimized FFmpeg build:

### Audio Format Conversion

```bash
# Convert MP3 to AAC
./ffmpeg -i input.mp3 -c:a aac -b:a 128k output.aac

# Convert WAV to MP3
./ffmpeg -i input.wav -c:a libmp3lame -q:a 2 output.mp3
```

### Audio Processing

```bash
# Normalize audio volume
./ffmpeg -i input.mp3 -filter:a loudnorm output.mp3

# Change audio speed (1.5x faster)
./ffmpeg -i input.mp3 -filter:a "atempo=1.5" output.mp3

# Detect silence in audio
./ffmpeg -i input.mp3 -af silencedetect=n=-50dB:d=1 -f null -
```

## Performance Considerations

- The minimized FFmpeg binary is optimized for size, not performance
- For Lambda, consider increasing memory allocation for better performance
- Use the `-threads` parameter to control CPU usage (e.g., `-threads 2`)
- For large files, consider streaming through FFmpeg rather than loading entire files into memory
