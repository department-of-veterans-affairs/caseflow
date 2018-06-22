import { ACTIONS } from './constants';
import { update } from '../util/ReducerUtil';

export const initialState = {};

const reducers = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.RECEIVE_PAST_UPLOADS:
    return update(state, {
      $set: action.payload.pastUploads
    });
  default:
    return state;
  }
};

export default reducers;
