import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './correspondenceDetailsConstants';

export const initialState = {

  bannerAlert: {},
  correspondenceInfo: {
    tasksUnrelatedToAppeal: {}
  },
  tasksUnrelatedToAppealEmpty: false,

};

export const correspondenceDetailsReducer = (state = initialState, action = {}) => {
  switch (action.type) {

  case ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER:
    return update(state, {
      bannerAlert: {
        $set: action.payload.bannerAlert
      }
    });
  case ACTIONS.CORRESPONDENCE_INFO:
    return update(state, {
      correspondenceInfo: {
        $set: action.payload.correspondence
      }
    });
  case ACTIONS.TASKS_UNRELATED_TO_APPEAL_EMPTY:
    return update(state, {
      tasksUnrelatedToAppealEmpty: {
        $set: action.payload.tasksUnrelatedToAppealEmpty
      }
    });
  default:
    return state;
  }
};

export default correspondenceDetailsReducer;