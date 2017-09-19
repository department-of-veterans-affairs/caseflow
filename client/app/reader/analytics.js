import _ from 'lodash';

export const CATEGORIES = {
  VIEW_DOCUMENT_PAGE: 'Document Viewer',
  CLAIMS_FOLDER_PAGE: 'Claims Folder',
  CASE_SELECTION_PAGE: 'Case Selection'
};

export const ACTION_NAMES = {
  VIEW_NEXT_DOCUMENT: 'view-next-document',
  VIEW_PREVIOUS_DOCUMENT: 'view-previous-document'
};

export const INTERACTION_TYPES = {
  VISIBLE_UI: 'visible-ui',
  KEYBOARD_SHORTCUT: 'keyboard-shortcut'
};

export const ENDPOINT_NAMES = {
  DOCUMENT: 'document',
  ANNOTATION: 'annotation',
  MARK_DOC_AS_READ: 'mark-doc-as-read',
  TAG: 'tag',
  APPEAL_DETAILS: 'appeal-details',
  APPEAL_DETAILS_BY_VET_ID: 'appeal-details-by-vet-id'
}

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
