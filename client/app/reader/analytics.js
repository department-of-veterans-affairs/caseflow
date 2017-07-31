import Analytics from '../util/AnalyticsUtil';
import _ from 'lodash';

export const CATEGORIES = {
  VIEW_DOCUMENT_PAGE: 'Document Viewer',
  CLAIMS_FOLDER_PAGE: 'Claims Folder'
}

export const reduxAnalyticsMiddleware = () => (next) => ({meta, ...action}) => {
  if (meta) {
    if (_.isFunction(meta.analytics)) {
      meta.analytics(Analytics.event.bind(Analytics));
    } else {
      Analytics.event(meta.analytics.category, meta.analytics.action, meta.analytics.label);
    }
  }

  return next(action);
}
