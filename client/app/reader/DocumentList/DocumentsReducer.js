import _ from 'lodash';

import * as Constants from './actionTypes';
import { DOCUMENTS_OR_COMMENTS_ENUM } from '../constants';
import { update } from '../../util/ReducerUtil';

const documentsReducer = (state = {}, action = {}) => {
  switch (action.type) {
  case Constants.RECEIVE_DOCUMENTS:
    return _(action.payload.documents).
      map((doc) => [
        doc.id, {
          ...doc,
          receivedAt: doc.received_at,
          listComments: false
        }
      ]).
      fromPairs().
      value();
  case Constants.TOGGLE_DOCUMENT_CATEGORY_FAIL:
    return update(
      state,
      {
        [action.payload.docId]: {
          [action.payload.categoryKey]: {
            $set: action.payload.categoryValueToRevertTo
          }
        }
      });
  case Constants.TOGGLE_DOCUMENT_CATEGORY:
    return update(
      state,
      {
        [action.payload.docId]: {
          [action.payload.categoryKey]: {
            $set: action.payload.toggleState
          }
        }
      });
  case Constants.SET_VIEWING_DOCUMENTS_OR_COMMENTS:
    return _.mapValues(state, (doc) => ({
      ...doc,
      listComments: action.payload.documentsOrComments === DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS
    }));
  case Constants.TOGGLE_COMMENT_LIST:
    return (docs) =>
      _.mapValues(docs, (doc) => ({
        ...doc,
        listComments: action.payload.documentsOrComments === DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS
      }));
  default:
    return state;
  }

};

export default documentsReducer;
