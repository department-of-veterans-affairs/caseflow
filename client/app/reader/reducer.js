import * as Constants from './constants';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';
import update from 'immutability-helper';

export const initialState = {
  ui: {
    pdf: {},
    pdfSidebar: {
      showTagErrorMsg: false,
      hidePdfSidebar: false
    },
    pdfList: {
      lastReadDocId: null,
      filters: {
        category: {}
      },
      dropdowns: {
        category: false
      }
    }
  },
  documents: {}
};

const updateFilteredDocIds = (nextState) => {
  const activeCategoryFilters = _(nextState.ui.pdfList.filters.category).
        toPairs().
        filter((([key, value]) => value)). // eslint-disable-line no-unused-vars
        map(([key]) => categoryFieldNameOfCategoryName(key)).
        value();

  const filteredIds = _(nextState.documents).
    filter(
      (doc) => !activeCategoryFilters.length ||
        _.every(activeCategoryFilters, (categoryFieldName) => doc[categoryFieldName])
    ).
    map('id').
    value();

  return update(nextState, {
    ui: {
      filteredDocIds: {
        $set: filteredIds
      }
    }
  });
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
            map((doc) => [doc.id, doc]).
            fromPairs().
            value()
        }
      }
    ));
  case Constants.SET_SORT_BY:
    return update(state, {
      ui: {
        sort: {
          sortBy: {
            $set: action.payload.sortBy
          }
        }
      }
    });
  case Constants.SELECT_CURRENT_VIEWER_PDF:
    return update(state, {
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
    });
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
          pdfList: {
            filters: {
              category: {
                [action.payload.categoryName]: {
                  $set: action.payload.checked
                }
              }
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
    return update(
      state,
      {
        ui: {
          pdfList: {
            lastReadDocId: {
              $set: action.payload.docId
            }
          }
        }
      }
    );
  default:
    return state;
  }
};
