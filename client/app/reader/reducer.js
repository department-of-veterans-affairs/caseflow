/* eslint-disable max-lines */
import * as Constants from './constants';

import _ from 'lodash';

import { update } from '../util/ReducerUtil';
import { timeFunction } from '../util/PerfDebug';

const setErrorMessageState = (state, errorType, isVisible, errorMsg = null) =>
  update(
    state,
    {
      ui: {
        pdfSidebar: {
          error: {
            [errorType]: {
              visible: { $set: isVisible },
              message: { $set: isVisible ? errorMsg : null }
            }
          }
        }
      }
    },
  );

const hideErrorMessage = (state, errorType, errorMsg = null) => setErrorMessageState(state, errorType, false, errorMsg);
const showErrorMessage = (state, errorType, errorMsg = null) => setErrorMessageState(state, errorType, true, errorMsg);

const initialPdfSidebarErrorState = {
  tag: { visible: false,
    message: null },
  category: { visible: false,
    message: null },
  annotation: { visible: false,
    message: null }
};

export const initialState = {
  loadedAppealId: null,
  loadedAppeal: {},
  initialDataLoadingFail: false,
  didLoadAppealFail: false,
  initialCaseLoadingFail: false,
  openedAccordionSections: [
    'Categories', 'Issue tags', Constants.COMMENT_ACCORDION_KEY
  ],
  ui: {
    tagOptions: [],
    pdf: {
      pdfsReadyToShow: {},
      hidePdfSidebar: false,
      jumpToPageNumber: null,
      scrollTop: 0,
      hideSearchBar: true
    },
    pdfSidebar: {
      error: initialPdfSidebarErrorState
    }
  },
  pageDimensions: {},
  pdfDocuments: {},
  documentErrors: {},
  text: []
};

export const reducer = (state = initialState, action = {}) => {
  let allTags;
  let uniqueTags;

  switch (action.type) {
  case Constants.COLLECT_ALL_TAGS_FOR_OPTIONS:
    allTags = Array.prototype.concat.apply([], _(action.payload).
      map((doc) => {
        return doc.tags ? doc.tags : [];
      }).
      value());
    uniqueTags = _.uniqWith(allTags, _.isEqual);

    return update(
      state,
      {
        ui: {
          tagOptions: {
            $set: uniqueTags
          }
        }
      }
    );
  case Constants.RECEIVE_APPEAL_DETAILS:
    return update(state,
      {
        loadedAppeal: {
          $set: action.payload.appeal
        }
      }
    );
  case Constants.RECEIVE_APPEAL_DETAILS_FAILURE:
    return update(state,
      {
        didLoadAppealFail: {
          $set: action.payload.failedToLoad
        }
      }
    );
  case Constants.JUMP_TO_PAGE:
    return update(
      state,
      {
        ui: {
          pdf: {
            $merge: {
              jumpToPageNumber: action.payload.pageNumber
            }
          }
        }
      }
    );
  case Constants.RESET_JUMP_TO_PAGE:
    return update(
      state,
      {
        ui: {
          pdf: {
            $merge: {
              jumpToPageNumber: null
            }
          }
        }
      }
    );
  case Constants.SCROLL_TO_SIDEBAR_COMMENT:
    return update(state, {
      ui: {
        pdf: {
          scrollToSidebarComment: { $set: action.payload.scrollToSidebarComment }
        }
      }
    });
  case Constants.SET_DOC_SCROLL_POSITION:
    return update(state, {
      ui: {
        pdf: {
          scrollTop: { $set: action.payload.scrollTop }
        }
      }
    });
  case Constants.SCROLL_TO_COMMENT:
    return update(state, {
      ui: { pdf: { scrollToComment: { $set: action.payload.scrollToComment } } }
    });
  case Constants.TOGGLE_PDF_SIDEBAR:
    return update(state,
      { ui: { pdf: { hidePdfSidebar: { $set: !state.ui.pdf.hidePdfSidebar } } } }
    );
  case Constants.TOGGLE_SEARCH_BAR:
    return update(state,
      { ui: { pdf: { hideSearchBar: { $set: !state.ui.pdf.hideSearchBar } } } }
    );
  case Constants.SHOW_SEARCH_BAR:
    return update(state,
      { ui: { pdf: { hideSearchBar: { $set: false } } } }
    );
  case Constants.HIDE_SEARCH_BAR:
    return update(state,
      { ui: { pdf: { hideSearchBar: { $set: true } } } }
    );
  case Constants.SET_OPENED_ACCORDION_SECTIONS:
    return update(
      state,
      {
        openedAccordionSections: {
          $set: action.payload.openedAccordionSections
        }
      }
    );
  case Constants.SET_UP_PAGE_DIMENSIONS:
    return update(
      state,
      {
        pageDimensions: {
          [`${action.payload.file}-${action.payload.pageIndex}`]: {
            $set: {
              ...action.payload.dimensions,
              file: action.payload.file,
              pageIndex: action.payload.pageIndex
            }
          }
        }
      }
    );
  case Constants.SET_PDF_DOCUMENT:
    return update(
      state,
      {
        pdfDocuments: {
          [action.payload.file]: {
            $set: action.payload.doc
          }
        }
      }
    );
  case Constants.CLEAR_PDF_DOCUMENT:
    if (action.payload.doc && _.get(state.pdfDocuments, [action.payload.file]) === action.payload.doc) {
      return update(
        state,
        {
          pdfDocuments: {
            [action.payload.file]: {
              $set: null
            }
          }
        });
    }

    return state;
  case Constants.SET_DOCUMENT_LOAD_ERROR:
    return update(state, {
      documentErrors: {
        [action.payload.file]: {
          $set: true
        }
      }
    });
  case Constants.CLEAR_DOCUMENT_LOAD_ERROR:
    return update(state, {
      documentErrors: {
        [action.payload.file]: {
          $set: false
        }
      }
    });
  case Constants.SET_LOADED_APPEAL_ID:
    return update(state, {
      loadedAppealId: {
        $set: action.payload.vacolsId
      }
    });

  // errors
  case Constants.HIDE_ERROR_MESSAGE:
    return hideErrorMessage(state, action.payload.messageType);
  case Constants.SHOW_ERROR_MESSAGE:
    return showErrorMessage(state, action.payload.messageType, action.payload.errorMessage);
  case Constants.RESET_PDF_SIDEBAR_ERRORS:
    return update(state, {
      ui: {
        pdfSidebar: { error: { $set: initialPdfSidebarErrorState } }
      }
    });
  default:
    return state;
  }
};

export default timeFunction(
  reducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
