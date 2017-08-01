import Analytics from '../util/AnalyticsUtil';
import _ from 'lodash';

export const CATEGORIES = {
  VIEW_DOCUMENT_PAGE: 'Document Viewer',
  CLAIMS_FOLDER_PAGE: 'Claims Folder'
};

export const ACTION_NAMES = {
  VIEW_NEXT_DOCUMENT: 'view-next-document',
  VIEW_PREVIOUS_DOCUMENT: 'view-previous-document'
};

export const INTERACTION_TYPES = {
  CLICK: 'click',
  KEYBOARD: 'keyboard'
};

export const reduxAnalyticsMiddleware = (store) => (next) => (action) => {
  const dispatchedAction = next(action);
  const { meta } = action;

  if (meta) {
    if (_.isFunction(meta.analytics)) {
      meta.analytics(Analytics.event.bind(Analytics));
    } else {
      const label = _.isFunction(meta.analytics.label) ? meta.analytics.label(store.getState()) : meta.analytics.label;

      Analytics.event(meta.analytics.category, meta.analytics.action, label);
    }
  }

  return dispatchedAction;
};
