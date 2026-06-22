class YouTubeAdBlockerService {
  static String get cosmeticScript => """
    (function() {
      function cleanYoutubeAds() {
        // Elements to hide/remove
        const adSelectors = [
          '#player-ads',
          '#masthead-ad',
          'ytd-action-companion-ad-renderer',
          'ytd-display-ad-renderer',
          'ytd-promoted-video-renderer',
          'ytd-compact-promoted-item-renderer',
          '.video-ads',
          '.ytp-ad-module',
          '.ytp-ad-overlay-container',
          '.ytp-ad-overlay-image',
          'ytm-promoted-item-renderer',
          'ytm-companion-ad-renderer',
          'ytd-companion-card-renderer',
          'ytd-companion-ad-renderer',
          '.ad-container',
          '.ad-div'
        ];
        
        adSelectors.forEach(selector => {
          const elements = document.querySelectorAll(selector);
          elements.forEach(el => {
            el.style.setProperty('display', 'none', 'important');
            // Try to remove it from DOM to free resources and prevent layout shifts
            if (el.parentNode) {
              el.remove();
            }
          });
        });

        // Handle active video ad overlays and skip buttons
        const video = document.querySelector('video');
        const isAdShowing = document.querySelector('.ad-showing, .ad-interrupting, .ytp-ad-player-overlay');
        
        if (isAdShowing && video) {
          const skipBtn = document.querySelector('.ytp-ad-skip-button, .ytp-ad-skip-button-modern, .ytp-ad-skip-button-slot');
          if (skipBtn) {
            skipBtn.click();
          } else {
            // Fallback: If ad is showing but no skip button, speed it up and skip it
            if (!isNaN(video.duration) && video.currentTime < video.duration) {
              video.currentTime = video.duration - 0.1;
            }
          }
        }

        // Close small banner overlays inside the video player
        const overlayCloseButtons = document.querySelectorAll('.ytp-ad-overlay-close-button');
        overlayCloseButtons.forEach(btn => {
          btn.click();
        });
      }

      if (!window.zyroYoutubeAdBlockerStarted) {
        window.zyroYoutubeAdBlockerStarted = true;
        // Run frequently to catch ads before they render
        setInterval(cleanYoutubeAds, 300);
        cleanYoutubeAds();
      }
    })();
  """;
}
