export default {
  pageView(page) {
    window.analyticsPageView(page);
  },

  // Log event to Google Analytics
  // For more info on what categories, actions, and labels are, see:
  // https://support.google.com/analytics/answer/1033068#Anatomy
  event(category, action, label) {
    window.analyticsEvent(category, action, label);
  },
};
