export default {
  pageView(page) {
    if (window.analyticsPageView) {
      window.analyticsPageView(page);
    } else {
      this.logTrigger(
        `${'JS Google Analytics Page View\n' +
        'path: '}${page}\n` +
        `title: ${document.title}`
      );
    }
  },

  // Log event to Google Analytics
  // For more info on what categories, actions, and labels are, see:
  // https://support.google.com/analytics/answer/1033068#Anatomy
  event(category, action, label) {
    if (window.analyticsEvent) {
      window.analyticsEvent(category, action, label);
    } else {
      this.logTrigger(
        `${'JS Google Analytics Event\n' +
        'category: '}${category}\n` +
        `action: ${action}\n` +
        `label: ${label}`
      );
    }
  },

  // When not connected to Google Analytics, simply log
  // analytics events to the console
  logTrigger(description) {
    // eslint-disable-next-line no-console
    console.log(description);
  }
};
