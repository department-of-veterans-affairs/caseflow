import * as Constants from './actionTypes';
import { DOCUMENTS_OR_COMMENTS_ENUM } from '../constants';
import _ from 'lodash';
import { update } from '../../util/ReducerUtil';
import { hideErrorMessage, showErrorMessage, updateFilteredDocIds } from '../helpers/reducerHelper';

const initialState = {
  docFilterCriteria: {
    sort: {
      sortBy: 'receivedAt',
      sortAscending: true
    },
    category: {},
    tag: {},
    searchQuery: ''
  },
  pdfList: {
    scrollTop: null,
    lastReadDocId: null,
    dropdowns: {
      tag: false,
      category: false
    }
  },
  documents: {},
  viewingDocumentsOrComments: DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS,
};

const documentListReducer = (state = initialState, action = {}) => {
  let modifiedDocuments;

  switch (action.type) {
  case Constants.SET_SORT:
    return updateFilteredDocIds(update(state, {
      docFilterCriteria: {
        sort: {
          sortBy: {
            $set: action.payload.sortBy
          },
          sortAscending: {
            $apply: (prevVal) => !prevVal
          }
        }
      }
    }));
  case Constants.CLEAR_CATEGORY_FILTER:
    return updateFilteredDocIds(update(state, {
      docFilterCriteria: {
        category: {
          $set: {}
        }
      }
    }));
  case Constants.SET_CATEGORY_FILTER:
    return updateFilteredDocIds(update(state, {
      docFilterCriteria: {
        category: {
          [action.payload.categoryName]: {
            $set: action.payload.checked
          }
        }
      }
    }));
  case Constants.TOGGLE_FILTER_DROPDOWN:
    return (() => {
      const originalValue = _.get(
        state,
        ['pdfList', 'dropdowns', action.payload.filterName],
        false
      );

      return update(state, {
        pdfList: {
          dropdowns: {
            [action.payload.filterName]: {
              $set: !originalValue
            }
          }
        }
      });
    })();
  case Constants.TOGGLE_DOCUMENT_CATEGORY_FAIL:
    return update(
      showErrorMessage(state, 'category'), {
        documents: {
          [action.payload.docId]: {
            [action.payload.categoryKey]: {
              $set: action.payload.categoryValueToRevertTo
            }
          }
        }
      });
  case Constants.TOGGLE_DOCUMENT_CATEGORY:
    return update(
      hideErrorMessage(state, 'category'), {
        documents: {
          [action.payload.docId]: {
            [action.payload.categoryKey]: {
              $set: action.payload.toggleState
            }
          }
        }
      });
  // Tag Filters
  case Constants.SET_TAG_FILTER:
    return updateFilteredDocIds(update(state, {
      docFilterCriteria: {
        tag: {
          [action.payload.text]: {
            $set: action.payload.checked
          }
        }
      }
    }));
  case Constants.CLEAR_TAG_FILTER:
    return updateFilteredDocIds(update(state, {
      docFilterCriteria: {
        tag: {
          $set: {}
        }
      }
    }));
  // Scrolling
  case Constants.SET_DOC_LIST_SCROLL_POSITION:
    return update(state, {
      pdfList: {
        scrollTop: { $set: action.payload.scrollTop }
      }
    });
  // Document header
  case Constants.SET_SEARCH:
    return updateFilteredDocIds(update(state, {
      docFilterCriteria: {
        searchQuery: {
          $set: action.payload.searchQuery
        }
      }
    }));
  case Constants.CLEAR_ALL_SEARCH:
    return updateFilteredDocIds(update(state, {
      docFilterCriteria: {
        searchQuery: {
          $set: ''
        }
      }
    }));
  case Constants.CLEAR_ALL_FILTERS:
    return updateFilteredDocIds(update(state, {
      docFilterCriteria: {
        category: {
          $set: {}
        },
        tag: {
          $set: {}
        }
      },
      viewingDocumentsOrComments: {
        $set: DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS
      }
    }));
  case Constants.SET_VIEWING_DOCUMENTS_OR_COMMENTS:
    return update(state, {
      viewingDocumentsOrComments: {
        $set: action.payload.documentsOrComments
      },
      documents: {
        $apply: (docs) =>
          _.mapValues(docs, (doc) => ({
            ...doc,
            listComments: action.payload.documentsOrComments === DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS
          }))
      }
    });
  case Constants.TOGGLE_COMMENT_LIST:
    modifiedDocuments = update(state.documents, {
      [action.payload.docId]: {
        $merge: {
          listComments: !state.documents[action.payload.docId].listComments
        }
      }
    });

    return update(state, {
      documents: { $set: modifiedDocuments }
    });
  default:
    return state;
  }
};

export default documentListReducer;
