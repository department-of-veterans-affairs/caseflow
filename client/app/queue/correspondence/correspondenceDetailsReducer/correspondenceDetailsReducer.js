import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './correspondenceDetailsConstants';

export const initialState = {

  bannerAlert: {},
  correspondenceInfo: {
    tasksUnrelatedToAppeal: {}
  },
  showActionsDropdown: true

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
  case ACTIONS.SHOW_ACTIONS_DROP_DOWN:
    return update(state, {
      showActionsDropdown: {
        $set: action.payload.showActionsDropdown
      }
    });
  case ACTIONS.REMOVE_TASK_NOT_RELATED_TO_APPEAL:
    return update(state, {
      correspondenceInfo: {
        $set: action.payload.correspondence
      }
    });

  default:
    return state;
  }
};

export default correspondenceDetailsReducer;
