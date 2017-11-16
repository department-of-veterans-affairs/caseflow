import * as Constants from './actionTypes';
import {DOCUMENTS_OR_COMMENTS_ENUM} from '../constants';
import _ from 'lodash';
import {update} from '../../util/ReducerUtil';
import {updateFilteredDocIds} from '../helpers/reducerHelper';
import documentsReducer from './DocumentsReducer';
import annotationReducer from './AnnotationsReducer';

const updateLastReadDoc = (state, docId) => update(state, {
  ui: {
    pdfList: {
      lastReadDocId: {
        $set: docId
      }
    }
  }
});

const updateDocuments = (state, action) => update(state, {
  documents: {
    $set: documentsReducer(state.documents, action)
  }
});

const initialState = {
  loadedAppealId: null,
  loadedAppeal: {},
  didLoadAppealFail: false,
  documents: {},
  viewingDocumentsOrComments: DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS,
  ui: {
    tagOptions: [],
    searchCategoryHighlights: {},
    filteredDocIds: null,
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
    manifestVbmsFetchedAt: null,
    manifestVvaFetchedAt: null
  },

  annotations: {}
};

const documentListReducer = (state = initialState, action = {}) => {

  switch (action.type) {
  case Constants.SET_SORT:
    return updateFilteredDocIds(update(state, {
      ui: {
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
      }
    }));
  case Constants.CLEAR_CATEGORY_FILTER:
    return updateFilteredDocIds(update(state, {
      ui: {
        docFilterCriteria: {
          category: {
            $set: {}
          }
        }
      }
    }));
  case Constants.SET_CATEGORY_FILTER:
    return updateFilteredDocIds(update(state, {
      ui: {
        docFilterCriteria: {
          category: {
            [action.payload.categoryName]: {
              $set: action.payload.checked
            }
          }
        }
      }
    }));
  case Constants.TOGGLE_FILTER_DROPDOWN:
    return (() => {
      const originalValue = _.get(state, [
        'ui', 'pdfList', 'dropdowns', action.payload.filterName
      ], false);

      return update(state, {
        ui: {
          pdfList: {
            dropdowns: {
              [action.payload.filterName]: {
                $set: !originalValue
              }
            }
          }
        }
      });
    })();
  case Constants.TOGGLE_DOCUMENT_CATEGORY_FAIL:
    return update(state, {
      documents: {
        $set: documentsReducer(state.documents, action)
      }
    });
  case Constants.TOGGLE_DOCUMENT_CATEGORY:
    return update(state, {
      documents: {
        $set: documentsReducer(state.documents, action)
      }
    });
    // Tag Filters
  case Constants.SET_TAG_FILTER:
    return updateFilteredDocIds(update(state, {
      ui: {
        docFilterCriteria: {
          tag: {
            [action.payload.text]: {
              $set: action.payload.checked
            }
          }
        }
      }
    }));
  case Constants.CLEAR_TAG_FILTER:
    return updateFilteredDocIds(update(state, {
      ui: {
        docFilterCriteria: {
          tag: {
            $set: {}
          }
        }
      }
    }));
    // Scrolling
  case Constants.SET_DOC_LIST_SCROLL_POSITION:
    return update(state, {
      ui: {
        pdfList: {
          scrollTop: {
            $set: action.payload.scrollTop
          }
        }
      }
    });
    // Document header
  case Constants.SET_SEARCH:
    return updateFilteredDocIds(update(state, {
      ui: {
        docFilterCriteria: {
          searchQuery: {
            $set: action.payload.searchQuery
          }
        }
      }
    }));
  case Constants.CLEAR_ALL_SEARCH:
    return updateFilteredDocIds(update(state, {
      ui: {
        docFilterCriteria: {
          searchQuery: {
            $set: ''
          }
        }
      }
    }));
  case Constants.CLEAR_ALL_FILTERS:
    return updateFilteredDocIds(update(state, {
      ui: {
        docFilterCriteria: {
          category: {
            $set: {}
          },
          tag: {
            $set: {}
          }
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
        $set: documentsReducer(state.documents, action)
      }
    });
  case Constants.TOGGLE_COMMENT_LIST:
    return updateDocuments(state, action);
  case Constants.RECEIVE_DOCUMENTS:
    return updateFilteredDocIds(update(state, {
      documents: {
        $set: documentsReducer(state.documents, action)
      },
      loadedAppealId: {
        $set: action.payload.vacolsId
      }
    }));
  case Constants.RECEIVE_APPEAL_DETAILS:
    return update(state, {
      loadedAppeal: {
        $set: action.payload.appeal
      }
    });
  case Constants.RECEIVE_ANNOTATIONS:
    return updateFilteredDocIds(update(state, {
      annotations: annotationReducer(state.annotations, action)
    }));
  case Constants.SELECT_CURRENT_VIEWER_PDF:
    return updateLastReadDoc(update(state, {
      documents: {
        $set: documentsReducer(state.documents, action)
      }
    }), action.payload.docId);
  case Constants.ROTATE_PDF_DOCUMENT:
  case Constants.REQUEST_NEW_TAG_CREATION:
  case Constants.REQUEST_NEW_TAG_CREATION_FAILURE:
  case Constants.REQUEST_NEW_TAG_CREATION_SUCCESS:
  case Constants.REQUEST_REMOVE_TAG:
  case Constants.REQUEST_REMOVE_TAG_SUCCESS:
    return updateDocuments(state, action);
  default:
    return state;
  }
};

export default documentListReducer;
