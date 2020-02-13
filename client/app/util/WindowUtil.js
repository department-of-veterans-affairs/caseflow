export default {
  reloadPage() {
    window.location.href = window.location.pathname + window.location.search;
  },

  // Does a reload with POST data.
  reloadWithPOST() {
    // https://stackoverflow.com/questions/41020403/reload-a-page-with-location-href-or-window-location-reloadtrue
    window.location.reload()
  }
};
