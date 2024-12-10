import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './correspondenceDetailsConstants';

export const initialState = {

  bannerAlert: {},
  waiveEvidenceAlertBanner: {},
  taskRelatedToAppealBanner: {},
  correspondenceInfo: {
    tasksUnrelatedToAppeal: {}
  },
  tasksUnrelatedToAppealEmpty: false,
  expandedLinkedAppeals: [],
  veteranInformation: {},
  correspondenceStatus: {},
  mailTasks: {},
  // might be the same as expandedLinkedAppeals
  linkedAppeals: {},
  // array of appeal Ids
  existingAppeals: [],
  tasksNotRelatedToAnAppeal: {},
  correspondenceTypes: {},
  generalInformation: {},
  responseLetters: {},
  linkedCorrespondences: {},
  allCorrespondences: {}
};

export const correspondenceDetailsReducer = (state = initialState, action = {}) => {
  switch (action.type) {

  case ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER:
    return update(state, {
      bannerAlert: {
        $set: action.payload.bannerAlert
      }
    });
  case ACTIONS.SET_TASK_RELATED_TO_APPEAL_BANNER:
    return update(state, {
      taskRelatedToAppealBanner: {
        $set: action.payload.taskRelatedToAppealBanner
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
  case ACTIONS.EVIDENCE_SUBMISSION_BANNER:
    return update(state, {
      waiveEvidenceAlertBanner: {
        $set: action.payload.waiveEvidenceAlertBanner
      }
    });
  case ACTIONS.EXPANDED_LINKED_APPEALS:
    return update(state, {
      expandedLinkedAppeals: {
        $set: action.payload.expandedLinkedAppeals
      }
    });
  case ACTIONS.VETERAN_INFORMATION:
    return update(state, {
      veteranInformation: {
        $set: action.payload.veteranInformation
      }
    });
  default:
    return state;
  }
};

export default correspondenceDetailsReducer;
