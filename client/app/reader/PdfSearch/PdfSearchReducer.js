import { update } from '../../util/ReducerUtil';
import * as Constants from './actionTypes';

const initialState = {
  matchIndex: 0,
  indexToHighlight: null,
  relativeIndex: 0,
  pageIndexWithMatch: null,
  extractedText: {}
};

export default function searchReducer(state = initialState, action = {}) {
  switch (action.type) {
  case Constants.UPDATE_SEARCH_INDEX:
    return update(state, {
      matchIndex: {
        $apply: (index) => action.payload.increment ? index + 1 : index - 1
      }
    });
  case Constants.SET_SEARCH_INDEX:
    return update(state, {
      matchIndex: {
        $set: action.payload.index
      }
    });
  case Constants.SET_SEARCH_INDEX_TO_HIGHLIGHT:
    return update(state, {
      indexToHighlight: {
        $set: action.payload.index
      }
    });
  case Constants.UPDATE_SEARCH_INDEX_PAGE_INDEX:
    return update(state, {
      pageIndexWithMatch: {
        $set: action.payload.index
      }
    });
  case Constants.UPDATE_SEARCH_RELATIVE_INDEX:
    return update(state, {
      relativeIndex: {
        $set: action.payload.index
      }
    });
  case Constants.GET_DOCUMENT_TEXT:
    return update(state, {
      extractedText: {
        $merge: action.payload.textObject
      }
    });
  default:
    return state;
  }
}
