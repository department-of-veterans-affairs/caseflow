import { ACTIONS } from './constants';
import { update } from '../util/ReducerUtil';

export const initialState = {};

const reducers = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.RECEIVE_PAST_UPLOADS:
    return update(state, {
      pastUploads: {
        $set: action.payload.pastUploads
      }
    });
  case ACTIONS.FILE_TYPE_CHANGE:
    return update(state, {
      fileType: {
        $set: action.payload.fileType
      }
    });
  default:
    return state;
  }
};

export default reducers;
