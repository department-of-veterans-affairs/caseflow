import querystring from 'querystring';
import * as Constants from './actionTypes';
import _ from 'lodash';
import { update } from '../../util/ReducerUtil';

const updateLastReadDoc = (state, docId) => update(state, {
  pdfList: {
    lastReadDocId: {
      $set: docId
    }
  }
});

const getQueueRedirectUrl = () => {
  const query = querystring.parse(window.location.search.slice(1));

  if (!query.queue_redirect_url) {
    return null;
  }

  return decodeURIComponent(query.queue_redirect_url);
};

const getQueueTaskType = () => {
  const query = querystring.parse(window.location.search.slice(1));

  if (!query.queue_task_type) {
    return null;
  }

  return decodeURIComponent(query.queue_task_type);
};

const initialState = {
  showBandwidthBanner: false,
  queueRedirectUrl: getQueueRedirectUrl(),
  queueTaskType: getQueueTaskType(),
  viewingDocumentsOrComments: Constants.DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS,
  searchCategoryHighlights: {},
  filteredDocIds: null,
  docFilterCriteria: {
    sort: {
      sortBy: 'receivedAt',
      sortAscending: true
    },
    category: {},
    tag: {},
    document: {},
    docTypeList: '',
    searchQuery: '',
    receiptFilterType: '',
    receiptFilterDates: {
      fromDate: '',
      toDate: '',
      onDate: ''
    },
  },
  pdfList: {
    scrollTop: null,
    lastReadDocId: null,
    dropdowns: {
      tag: false,
      category: false,
      document: false,
      receiptDate: false
    }
  },
  manifestVbmsFetchedAt: null
};

const documentListReducer = (state = initialState, action = {}) => {

  switch (action.type) {
  case Constants.LAST_READ_DOCUMENT:
    return updateLastReadDoc(state, action.payload.docId);
  case Constants.SET_SORT:
    return update(state, {
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
    });
  case Constants.CLEAR_CATEGORY_FILTER:
    return update(state, {
      docFilterCriteria: {
        category: {
          $set: {}
        }
      }
    });

  case Constants.SET_CATEGORY_FILTER:
    return update(state, {
      docFilterCriteria: {
        category: {
          [action.payload.categoryName]: {
            $set: action.payload.checked
          }
        }
      }
    });
  case Constants.TOGGLE_FILTER_DROPDOWN:
    return (() => {
      const originalValue = _.get(state, [
        'pdfList', 'dropdowns', action.payload.filterName
      ], false);

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

    // Tag Filters
  case Constants.SET_TAG_FILTER:
    return update(state, {
      docFilterCriteria: {
        tag: {
          [action.payload.text]: {
            $set: action.payload.checked
          }
        }
      }
    });
  case Constants.ENABLE_BANDWIDTH_BANNER:
    return update(state, {
      showBandwidthBanner: {
        $set: true
      }
    });
  case Constants.CLEAR_TAG_FILTER:
    return update(state, {
      docFilterCriteria: {
        tag: {
          $set: {}
        }
      }
    });

    // Receipt date filter
  case Constants.SET_RECEIPT_DATE_FILTER:
    return update(state, {
      docFilterCriteria: {
        receiptFilterType: {
          $set: action.payload.receiptFilterType
        },
        receiptFilterDates: {
          $set: action.payload.receiptDatesHash
        }
      },
    });
    // Scrolling
  case Constants.SET_DOC_LIST_SCROLL_POSITION:
    return update(state, {
      pdfList: {
        scrollTop: {
          $set: action.payload.scrollTop
        }
      }
    });
  case Constants.SET_VIEWING_DOCUMENTS_OR_COMMENTS:
    return update(state, {
      viewingDocumentsOrComments: {
        $set: action.payload.documentsOrComments
      }
    });

    // Document filter
  case Constants.SET_DOC_FILTER:
    return update(state, {
      docFilterCriteria: {
        document: {
          [action.payload.text]: {
            $set: action.payload.checked
          }
        }
      }
    });

  case Constants.CLEAR_DOC_FILTER:
    return update(state, {
      docFilterCriteria: {
        document: {
          $set: {}
        }
      }
    });

    // holds the unique different document types for reader.
  case Constants.SET_DOC_TYPES:
    return update(state, {
      docFilterCriteria: {
        docTypeList: {
          $set: action.payload.docToAdd
        }
      }
    });

  // Document header
  case Constants.SET_SEARCH:
    return update(state, {
      docFilterCriteria: {
        searchQuery: {
          $set: action.payload.searchQuery
        }
      }
    });
  case Constants.CLEAR_ALL_SEARCH:
    return update(state, {
      docFilterCriteria: {
        searchQuery: {
          $set: ''
        }
      }
    });
  case Constants.CLEAR_ALL_FILTERS:
    return update(state, {
      docFilterCriteria: {
        category: {
          $set: {}
        },
        tag: {
          $set: {}
        },
        document: {
          $set: {}
        },
        receiptFilterType: { $set: '' },
        receiptFilterDates: {
          $set: {}
        }
      },
      viewingDocumentsOrComments: {
        $set: Constants.DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS
      }
    });
  case Constants.RECEIVE_MANIFESTS:
    return update(state, {
      manifestVbmsFetchedAt: {
        $set: action.payload.manifestVbmsFetchedAt
      }
    });
  case Constants.UPDATE_FILTERED_RESULTS:
    return update(state, {
      filteredDocIds: { $set: action.payload.filteredIds },
      searchCategoryHighlights: { $set: action.payload.searchCategoryHighlights }
    });
  default:
    return state;
  }
};

export default documentListReducer;
