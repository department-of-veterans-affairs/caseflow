import { update } from '../../util/ReducerUtil';
import { ACTIONS } from './uiConstants';

const initialState = {
  userCssId: ''
};

const hearingScheduleUiReducer = (state = initialState, action = {}) => {
  switch (action.type) {
    case ACTIONS.SET_USER_CSS_ID:
      return update(state, {
        userCssId: { $set: action.payload.cssId }
      });
    default:
      return state;
  }
};

export default hearingScheduleUiReducer;
