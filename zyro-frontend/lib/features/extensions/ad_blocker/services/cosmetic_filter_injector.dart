class CosmeticFilterInjector {
  static String get cosmeticScript => """
    (function() {
      function applyCosmeticFilters() {
        const adSelectors = [
          '.adsbygoogle',
          'amp-ad',
          'div[class*="ad-box"]',
          'div[class*="ad-container"]',
          'div[id*="ad-slot"]',
          'div[class*="ad-unit"]',
          'iframe[src*="doubleclick"]',
          'iframe[id*="google_ads"]',
          'div[class*="sponsored-post"]',
          'a[href*="doubleclick.net"]',
          '.ad-placement',
          '.ad-wrapper',
          '#ad-banner',
          '.banner-ad',
          '.header-ad',
          'div[id*="div-gpt-ad"]',
          'div[class*="taboola-ad"]'
        ];
        
        adSelectors.forEach(selector => {
          const elements = document.querySelectorAll(selector);
          elements.forEach(el => {
            el.style.setProperty('display', 'none', 'important');
          });
        });
      }

      if (!window.zyroCosmeticFilterStarted) {
        window.zyroCosmeticFilterStarted = true;
        setInterval(applyCosmeticFilters, 1000);
        applyCosmeticFilters();
      }
    })();
  """;
}
