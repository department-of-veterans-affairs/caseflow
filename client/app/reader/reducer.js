/* eslint-disable max-lines */

import * as Constants from './constants';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';
import update from 'immutability-helper';

const metadataContainsString = (searchQuery, doc) =>
  doc.type.toLowerCase().includes(searchQuery) ||
  doc.receivedAt.toLowerCase().includes(searchQuery);

const commentContainsString = (searchQuery, annotationStorage, doc) =>
  annotationStorage.getAnnotationByDocumentId(doc.id).reduce((acc, annotation) =>
    acc || annotation.comment.toLowerCase().includes(searchQuery)
  , false);

const categoryContainsString = (searchQuery, doc) =>
  Object.keys(Constants.documentCategories).reduce((acc, category) =>
    acc || (category.includes(searchQuery) &&
      doc[categoryFieldNameOfCategoryName(category)])
  , false);

const tagContainsString = (searchQuery, doc) =>
  Object.keys(doc.tags || {}).reduce((acc, tag) => {
    return acc || (doc.tags[tag].text.toLowerCase().includes(searchQuery));
  }
  , false);

const searchString = (searchQuery, annotationStorage) => (doc) =>
  !searchQuery || searchQuery.split(' ').some((searchWord) => {
    return searchWord.length > 0 && (
      metadataContainsString(searchWord, doc) ||
      categoryContainsString(searchWord, doc) ||
      commentContainsString(searchWord, annotationStorage, doc) ||
      tagContainsString(searchWord, doc));
  });

const updateFilteredDocIds = (nextState) => {
  const { docFilterCriteria } = nextState.ui;
  const activeCategoryFilters = _(docFilterCriteria.category).
        toPairs().
        filter((([key, value]) => value)). // eslint-disable-line no-unused-vars
        map(([key]) => categoryFieldNameOfCategoryName(key)).
        value();

  const searchQuery = _.get(docFilterCriteria, 'searchQuery', '').toLowerCase();

  const filteredIds = _(nextState.documents).
    filter(
      (doc) => !activeCategoryFilters.length ||
        _.some(activeCategoryFilters, (categoryFieldName) => doc[categoryFieldName])
    ).
    filter(
      searchString(searchQuery, nextState.annotationStorage)
    ).
    sortBy(docFilterCriteria.sort.sortBy).
    map('id').
    value();

  if (docFilterCriteria.sort.sortAscending) {
    filteredIds.reverse();
  }

  return update(nextState, {
    ui: {
      filteredDocIds: {
        $set: filteredIds
      }
    }
  });
};

const updateLastReadDoc = (state, docId) =>
  update(
    state,
    {
      ui: {
        pdfList: {
          lastReadDocId: {
            $set: docId
          }
        }
      }
    }
  );

export const initialState = {
  annotationStorage: null,
  ui: {
    filteredDocIds: null,
    docFilterCriteria: {
      sort: {
        sortBy: 'receivedAt',
        sortAscending: false
      },
      category: {},
      tag: {},
      searchQuery: ''
    },
    pdf: {
      currentRenderedFile: null,
      pdfsReadyToShow: {},
      hidePdfSidebar: false
    },
    pdfSidebar: {
      showTagErrorMsg: false,
      commentFlowState: null,
      hidePdfSidebar: false
    },
    pdfList: {
      lastReadDocId: null,
      dropdowns: {
        category: false
      }
    }
  },
  documents: {}
};

export default (state = initialState, action = {}) => {
  let categoryKey;

  switch (action.type) {
  case Constants.RECEIVE_DOCUMENTS:
    return updateFilteredDocIds(update(
      state,
      {
        documents: {
          $set: _(action.payload).
            map((doc) => [
              doc.id, {
                ...doc,
                receivedAt: doc.received_at
              }
            ]).
            fromPairs().
            value()
        }
      }
    ));
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
  case Constants.SELECT_CURRENT_VIEWER_PDF:
    return updateLastReadDoc(update(state, {
      ui: {
        pdfSidebar: { showTagErrorMsg: { $set: false } },
        pdf: {
          currentRenderedFile: {
            $set: action.payload.docId
          }
        }
      },
      documents: {
        [action.payload.docId]: {
          $merge: {
            opened_by_current_user: true
          }
        }
      }
    }), action.payload.docId);
  case Constants.UNSELECT_CURRENT_VIEWER_PDF:
    return update(updateFilteredDocIds(state), {
      ui: {
        pdf: {
          currentRenderedFile: {
            $set: null
          }
        }
      }
    });
  case Constants.SET_PDF_READY_TO_SHOW:
    return update(state, {
      ui: {
        pdf: {
          pdfsReadyToShow: {
            $set: {
              [action.payload.docId]: true
            }
          }
        }
      }
    });
  case Constants.TOGGLE_DOCUMENT_CATEGORY:
    categoryKey = categoryFieldNameOfCategoryName(action.payload.categoryName);

    return update(
      state,
      {
        documents: {
          [action.payload.docId]: {
            [categoryKey]: {
              $set: action.payload.toggleState
            }
          }
        }
      }
    );
  case Constants.TOGGLE_FILTER_DROPDOWN:
    return (() => {
      const originalValue = _.get(
        state,
        ['ui', 'pdfList', 'dropdowns', action.payload.filterName],
        false
      );

      return update(state,
        {
          ui: {
            pdfList: {
              dropdowns: {
                [action.payload.filterName]: {
                  $set: !originalValue
                }
              }
            }
          }
        }
      );
    })();
  case Constants.REQUEST_NEW_TAG_CREATION:
    return update(state, {
      ui: { pdfSidebar: { showTagErrorMsg: { $set: false } } },
      documents: {
        [action.payload.docId]: {
          tags: {
            $push: action.payload.newTags
          }
        }
      }
    });
  case Constants.REQUEST_NEW_TAG_CREATION_FAILURE:
    return update(state, {
      ui: { pdfSidebar: { showTagErrorMsg: { $set: true } } },
      documents: {
        [action.payload.docId]: {
          tags: {
            $apply: (tags) =>
              _.differenceBy(
                tags,
                action.payload.tagsThatWereAttemptedToBeCreated,
                'text'
              )
          }
        }
      }
    });
  case Constants.REQUEST_NEW_TAG_CREATION_SUCCESS:
    return update(
      state,
      {
        documents: {
          [action.payload.docId]: {
            tags: {
              $set: action.payload.createdTags
            }
          }
        }
      }
    );
  case Constants.SET_CATEGORY_FILTER:
    return updateFilteredDocIds(update(
      state,
      {
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
  case Constants.CLEAR_ALL_FILTERS:
    return updateFilteredDocIds(update(
      state,
      {
        ui: {
          docFilterCriteria: {
            category: {
              $set: {}
            },
            tag: {
              $set: {}
            }
          }
        }
      }));
  case Constants.REQUEST_REMOVE_TAG:
    return update(state, {
      documents: {
        [action.payload.docId]: {
          tags: {
            $apply: (tags) => {
              const removedTagIndex = _.findIndex(tags, { id: action.payload.tagId });

              return update(tags, {
                [removedTagIndex]: {
                  $merge: {
                    pendingRemoval: true
                  }
                }
              });
            }
          }
        }
      }
    });
  case Constants.REQUEST_REMOVE_TAG_SUCCESS:
    return update(state, {
      ui: { pdfSidebar: { showTagErrorMsg: { $set: false } } },
      documents: {
        [action.payload.docId]: {
          tags: {
            $apply: (tags) => _.reject(tags, { id: action.payload.tagId })
          }
        }
      }
    });
  case Constants.SCROLL_TO_SIDEBAR_COMMENT:
    return update(state, {
      ui: {
        pdf: {
          scrollToSidebarComment: { $set: action.payload.scrollToSidebarComment }
        }
      }
    }
    );
  case Constants.REQUEST_REMOVE_TAG_FAILURE:
    return update(state, {
      ui: { pdfSidebar: { showTagErrorMsg: { $set: true } } },
      documents: {
        [action.payload.docId]: {
          tags: {
            $apply: (tags) => {
              const removedTagIndex = _.findIndex(tags, { id: action.payload.tagId });

              return update(tags, {
                [removedTagIndex]: {
                  $merge: {
                    pendingRemoval: false
                  }
                }
              });
            }
          }
        }
      }
    });
  case Constants.SCROLL_TO_COMMENT:
    return update(state, {
      ui: { pdf: { scrollToComment: { $set: action.payload.scrollToComment } } }
    });
  case Constants.TOGGLE_COMMENT_LIST:
    return update(
      state,
      {
        documents: {
          [action.payload.docId]: {
            listComments: {
              $set: !state.documents[action.payload.docId].listComments
            }
          }
        }
      }
    );
  case Constants.TOGGLE_PDF_SIDEBAR:
    return _.merge(
      {},
      state,
      {
        ui: {
          pdf: {
            hidePdfSidebar: !state.ui.pdf.hidePdfSidebar
          }
        }
      }
    );
  case Constants.LAST_READ_DOCUMENT:
    return updateLastReadDoc(state, action.payload.docId);
  case Constants.SET_COMMENT_FLOW_STATE:
    return update(
      state,
      {
        ui: {
          pdf: {
            commentFlowState: { $set: action.payload.state }
          }
        }
      }
    );
  case Constants.SET_ANNOTATION_STORAGE:
    return update(
      state,
      {
        annotationStorage: {
          $set: action.payload.annotationStorage
        }
      }
    );
  case Constants.CLEAR_ALL_SEARCH:
    return updateFilteredDocIds(update(
      state,
      {
        ui: {
          docFilterCriteria: {
            searchQuery: {
              $set: ''
            }
          }
        }
      }
    ));
  default:
    return state;
  }
};
/* eslint-enable max-lines */
