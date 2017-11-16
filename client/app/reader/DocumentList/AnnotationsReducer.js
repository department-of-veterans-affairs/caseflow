import _ from 'lodash';

import * as Constants from './actionTypes';
// import { update } from '../../util/ReducerUtil';

const documentsReducer = (state = {}, action = {}) => {
  switch (action.type) {
  case Constants.RECEIVE_ANNOTATIONS:
    return _(action.payload.annotations).
      map((annotation) => ({
        documentId: annotation.document_id,
        uuid: annotation.id,
        ...annotation
      })).
      keyBy('id').
      value();
  default:
    return state;
  }
};

export default documentsReducer;