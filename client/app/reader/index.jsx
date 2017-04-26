import React from 'react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware, compose } from 'redux';
import thunk from 'redux-thunk';
import DecisionReviewer from './DecisionReviewer';
import * as Constants from './constants';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';
import update from 'immutability-helper';

const initialState = {
  ui: {
    pdf: {},
    pdfSidebar: {
      showTagErrorMsg: false
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

export const readerReducer = (state = initialState, action = {}) => {
  let categoryKey;

  switch (action.type) {
  case Constants.RECEIVE_DOCUMENTS:
    return update(
      state,
      {
        documents: {
          $set: _(action.payload).
            map((doc) => [doc.id, doc]).
            fromPairs().
            value()
        }
      }
    );
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
    return update(
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
      });
  case Constants.REQUEST_REMOVE_TAG_SUCCESS:
    return update(state, {
      ui: { pdfSidebar: { showTagErrorMsg: { $set: false } } },
      documents: {
        [action.payload.docId]: {
          tags: { $set: state.documents[action.payload.docId].tags.
            filter((tag) => tag.id !== action.payload.tagId) }
        }
      }
    }
  );
  case Constants.REQUEST_REMOVE_TAG_FAILURE:
    return update(state, {
      ui: { pdfSidebar: { showTagErrorMsg: { $set: true } } }
    });
  case Constants.SET_CURRENT_RENDERED_FILE:
    return update(state, {
      ui: {
        pdfSidebar: { showTagErrorMsg: { $set: false } },
        pdf: { $merge: _.pick(action.payload, 'currentRenderedFile') }
      }
    });
  case Constants.SCROLL_TO_COMMENT:
    return update(state, {
      ui: { pdf: { $merge: _.pick(action.payload, 'scrollToComment') } }
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

  // eslint-disable-next-line no-underscore-dangle
const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;
const store =
  createStore(readerReducer, initialState, composeEnhancers(applyMiddleware(thunk)));

const Reader = (props) => {
  return <Provider store={store}>
      <DecisionReviewer {...props} />
  </Provider>;
};

export default Reader;
