import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './correspondenceDetailsConstants';

export const initialState = {

  bannerAlert: {},

};

export const correspondenceDetailsReducer = (state = initialState, action = {}) => {
  switch (action.type) {

  case ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER:
    return update(state, {
      bannerAlert: {
        $set: action.payload.bannerAlert
      }
    });

  default:
    return state;
  }
};

export default correspondenceDetailsReducer;
