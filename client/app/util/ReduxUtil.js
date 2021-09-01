import { debounce, isFunction } from 'lodash';

const debounceFns = {};

/**
 * Create a middleware you can pass into your Redux store to automatically fire Google Analytics events.
 * Redux actions with an meta.analytics property will be logged:
 *
 *    const action = {
 *      type: string
 *      meta: {
 *        analytics: {
 *          category: string?, // defaults to defaultCategory
 *          action: string?, // defaults to action.type
 *          label: string?|function(state: redux state): string,
 *          debounceMs: number?
 *        }
 *      }
 *    }
 *
 * meta.analytics.label is optional. If label is a function, then it will be invoked with the redux state after the
 * action is applied, and is expected to return the label to log. You can use this to dynamically set the label based
 * on how the action updated the state.
 *
 * If meta.analytics.debounceMs is passed, then a tracking event will only be fired every debounceMs milliseconds.
 * See https://lodash.com/docs/4.17.4#debounce for more detail. This is useful for noisy actions, where you want some
 * relative indicator of how often they're being fired, but tracking every action would be excessive.
 *
 * If meta.analytics is a function, then it will be invoked with a `triggerEvent` method, with type signature:
 *    function(category: string, action: string, label: string)
 *
 * You can use this to dynamically fire as many events for this action as you want. For instance, if clicking a button
 * collapses a number of accordion panes, you may wish to fire a separate event for each pane.
 *
 * @param {string?} defaultCategory a default category for all events.
 */
export const getReduxAnalyticsMiddleware = (defaultCategory) => (store) => (next) => (action) => {
  const dispatchedAction = next(action);
  const { meta } = action;

  if (meta?.analytics) {
    if (isFunction(meta.analytics)) {
      meta.analytics(window.analyticsEvent, defaultCategory, action.type);
    } else {
      // Safe-assign the analytics label
      const label = isFunction(meta?.analytics?.label) ?
        meta?.analytics?.label(store.getState()) :
        meta?.analytics?.label;

      if (!debounceFns[action.type]) {
        const category = meta?.analytics?.category || defaultCategory;
        const actionName = meta?.analytics?.action || action.type;

        debounceFns[action.type] = debounce(
          (eventLabel) => window.analyticsEvent(category, actionName, eventLabel),
          meta?.analytics?.debounceMs || 0
        );
      }

      debounceFns[action.type](label);
    }
  } else if (!action.type.includes('pending') && !action.type.includes('fulfilled')) {
    console.warn('No analytics present for action: ', action.type);
  }

  return dispatchedAction;
};
