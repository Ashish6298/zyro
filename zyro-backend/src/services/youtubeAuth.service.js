const fs = require('fs');

const RENDER_COOKIES_PATH = '/etc/secrets/youtube-cookies.txt';

function getYoutubeAuthOptions() {
  const configuredPath = process.env.YTDLP_COOKIES_PATH;
  const cookiesPath = configuredPath || RENDER_COOKIES_PATH;

  if (!fs.existsSync(cookiesPath)) {
    return {};
  }

  console.log('Using configured YouTube authentication cookies.');
  return { cookies: cookiesPath };
}

module.exports = { getYoutubeAuthOptions };
