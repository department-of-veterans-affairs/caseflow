/* eslint-disable max-lines */
import * as Constants from './constants';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';
import update from 'immutability-helper';
import { searchString } from './search';

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

const SHOW_EXPAND_ALL = false;

/**
 * This function takes all the documents and check the status of the
 * list comments in the document to see if Show All or Collapse All should be
 * shown based on the state.
 */
const getExpandAllState = (documents) => {
  let allExpanded = !SHOW_EXPAND_ALL;

  _.forOwn(documents, (doc) => {
    if (!doc.listComments) {
      allExpanded = SHOW_EXPAND_ALL;
    }
  });

  return Boolean(allExpanded);
};

export const initialState = {
  annotationStorage: null,
  ui: {
    filteredDocIds: null,
    expandAll: false,
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
  tagOptions: [],
  documents: {}
};

export default (state = initialState, action = {}) => {
  let categoryKey;
  let allTags;
  let uniqueTags;
  let modifiedDocuments;

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
        tagOptions: {
          $set: uniqueTags
        }
      }
    );
  case Constants.RECEIVE_DOCUMENTS:
    return updateFilteredDocIds(update(
      state,
      {
        documents: {
          $set: _(action.payload).
            map((doc) => [
              doc.id, {
                ...doc,
                receivedAt: doc.received_at,
                listComments: false
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
  case Constants.TOGGLE_EXPAND_ALL:
    return update(state, {
      documents: {
        $set: _.mapValues(state.documents, (document) => {
          return update(document, { listComments: { $set: !state.ui.expandAll } });
        })
      },
      ui: {
        $merge: { expandAll: !state.ui.expandAll }
      }
    });
  case Constants.TOGGLE_COMMENT_LIST:
    modifiedDocuments = update(state.documents,
      {
        [action.payload.docId]: {
          $merge: {
            listComments: !state.documents[action.payload.docId].listComments
          }
        }
      });

    return update(
      state,
      {
        documents: { $set: modifiedDocuments },
        ui: { $merge: { expandAll: getExpandAllState(modifiedDocuments) } }
      });
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
