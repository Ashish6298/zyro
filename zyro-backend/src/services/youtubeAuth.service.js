const fs = require('fs');
const os = require('os');
const path = require('path');

const RENDER_COOKIES_PATH = '/etc/secrets/youtube-cookies.txt';
const TEMP_COOKIES_PATH = path.join(os.tmpdir(), 'zyro-youtube-cookies.txt');

function getYoutubeAuthOptions() {
  const configuredPath = process.env.YTDLP_COOKIES_PATH;
  const cookiesPath = configuredPath || RENDER_COOKIES_PATH;

  if (!fs.existsSync(cookiesPath)) {
    return {};
  }

  // Render Secret Files are read-only, but yt-dlp updates its cookie jar.
  // Work with a writable copy while keeping the original secret protected.
  if (!fs.existsSync(TEMP_COOKIES_PATH)) {
    fs.copyFileSync(cookiesPath, TEMP_COOKIES_PATH);
  }

  console.log('Using configured YouTube authentication cookies.');
  return { cookies: TEMP_COOKIES_PATH };
}

module.exports = { getYoutubeAuthOptions };
