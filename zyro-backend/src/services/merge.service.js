const ffmpeg = require('fluent-ffmpeg');

function mergeStreams(videoPath, audioPath, outputPath) {
  return new Promise((resolve, reject) => {
    console.log(`Merging ${videoPath} and ${audioPath} to ${outputPath}`);
    const isWebm = outputPath.toLowerCase().endsWith('.webm');
    
    ffmpeg()
      .input(videoPath)
      .input(audioPath)
      .outputOptions('-c:v copy')
      .outputOptions(isWebm ? '-c:a copy' : '-c:a aac')
      .outputOptions('-shortest')
      .output(outputPath)
      .on('end', () => {
        console.log('Merge completed successfully.');
        resolve();
      })
      .on('error', (err) => {
        console.error('Merge error:', err);
        reject(err);
      })
      .run();
  });
}

function convertToMp3(audioPath, outputPath) {
  return new Promise((resolve, reject) => {
    console.log(`Converting ${audioPath} to MP3 at ${outputPath}`);
    ffmpeg()
      .input(audioPath)
      .audioCodec('libmp3lame')
      .audioBitrate('320k')
      .output(outputPath)
      .on('end', () => {
        console.log('Audio conversion to MP3 completed.');
        resolve();
      })
      .on('error', (err) => {
        console.error('Audio conversion error:', err);
        reject(err);
      })
      .run();
  });
}

module.exports = { mergeStreams, convertToMp3 };
