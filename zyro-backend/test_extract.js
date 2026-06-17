const { extractMetadata } = require('./src/services/videoExtractor.service');

(async () => {
  try {
    console.log('Testing extraction...');
    const meta = await extractMetadata('https://www.youtube.com/watch?v=s0JTpcDu1Tk');
    console.log('Success! Title:', meta.title);
    console.log('Formats count:', meta.formats.length);
  } catch (err) {
    console.error('Error occurred during test:', err);
  }
})();
