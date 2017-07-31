import Analytics from '../util/AnalyticsUtil';
import _ from 'lodash';

export const CATEGORIES = {
  VIEW_DOCUMENT_PAGE: 'Document Viewer',
  CLAIMS_FOLDER_PAGE: 'Claims Folder'
}

export const actionWithAnalytics = (action) => {
  if (_.isFunction(action.analytics)) {
    action.analytics(Analytics.event.bind(Analytics));
  } else {
    Analytics.event(action.analytics.category, event.analytics.action, event.analytics.label);
  }

  return _.omit(action, 'analytics');
}
