import _ from 'lodash';

const debounceFns = {};

export const reduxAnalyticsMiddleware = (store) => (next) => (action) => {
  const dispatchedAction = next(action);
  const { meta } = action;

  if (meta) {
    if (_.isFunction(meta.analytics)) {
      meta.analytics(window.analyticsEvent);
    } else {
      const label = _.isFunction(meta.analytics.label) ? meta.analytics.label(store.getState()) : meta.analytics.label;

      if (!debounceFns[action.type]) {
        debounceFns[action.type] = _.debounce(
          (eventLabel) => window.analyticsEvent(meta.analytics.category, meta.analytics.action, eventLabel),
          meta.analytics.debounceMs || 0
        );
      }

      debounceFns[action.type](label);
    }
  }

  return dispatchedAction;
};
