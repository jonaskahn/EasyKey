(function () {
  var STORAGE_KEY = 'easykey-lang';
  var SPARKLE_NAMESPACE = 'http://www.andymatuschak.org/xml-namespaces/sparkle';
  var root = document.documentElement;

  async function loadLatestVersion() {
    var versionLabel = document.getElementById('app-version');
    var appcastUrl = new URL('appcast.xml', window.location.href);
    appcastUrl.searchParams.set('_', Date.now().toString());

    try {
      var response = await fetch(appcastUrl, { cache: 'no-store' });
      if (!response.ok) throw new Error('Appcast request failed');

      var appcast = new DOMParser().parseFromString(await response.text(), 'application/xml');
      if (appcast.querySelector('parsererror')) throw new Error('Invalid appcast');

      var versionNode = appcast.getElementsByTagNameNS(SPARKLE_NAMESPACE, 'shortVersionString')[0];
      if (!versionNode || !versionNode.textContent.trim()) throw new Error('No release version');

      versionLabel.textContent = 'v' + versionNode.textContent.trim();
    } catch (error) {
      versionLabel.textContent = 'vN/A';
    }
  }

  function setLang(lang) {
    root.setAttribute('data-lang', lang);
    root.lang = lang;
    try { localStorage.setItem(STORAGE_KEY, lang); } catch (e) { /* ignore */ }
  }

  document.querySelectorAll('.lang-btn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      setLang(btn.getAttribute('data-lang-btn'));
    });
  });

  var saved = null;
  try { saved = localStorage.getItem(STORAGE_KEY); } catch (e) { /* ignore */ }
  setLang(saved === 'en' ? 'en' : 'vi');
  loadLatestVersion();
})();
