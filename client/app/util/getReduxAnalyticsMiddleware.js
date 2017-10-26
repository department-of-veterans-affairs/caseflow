import _ from 'lodash';

const debounceFns = {};

export const getReduxAnalyticsMiddleware = (defaultCategory) => (store) => (next) => (action) => {
  const dispatchedAction = next(action);
  const { meta } = action;

  if (meta) {
    if (_.isFunction(meta.analytics)) {
      meta.analytics(window.analyticsEvent);
    } else {
      const label = _.isFunction(meta.analytics.label) ? meta.analytics.label(store.getState()) : meta.analytics.label;

      if (!debounceFns[action.type]) {
        const category = meta.analytics.category || defaultCategory;
        const actionName = meta.analytics.action || action.type;

        debounceFns[action.type] = _.debounce(
          (eventLabel) => window.analyticsEvent(category, actionName, eventLabel),
          meta.analytics.debounceMs || 0
        );
      }

      debounceFns[action.type](label);
    }
  }

  return dispatchedAction;
};
