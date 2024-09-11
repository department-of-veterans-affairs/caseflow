import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './correspondenceDetailsConstants';

export const initialState = {

  bannerAlert: {},
  correspondenceInfo: {
    tasksUnrelatedToAppeal: {}
  },
  tasksUnrelatedToAppealEmpty: false,
  relatedCorrespondences: []

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
  case ACTIONS.SAVE_CHECKBOX_STATE:
    if (action.payload.isChecked) {
      return update(state, {
        relatedCorrespondences: {
          $push: [action.payload.correspondence]
        }
      });
    }

    return update(state, {
      relatedCorrespondences: {
        $set: state.relatedCorrespondences.filter((corr) => {
          return corr.uuid !== action.payload.correspondence.uuid;
        })
      }
    });
  default:
    return state;
  }
};

export default correspondenceDetailsReducer;
