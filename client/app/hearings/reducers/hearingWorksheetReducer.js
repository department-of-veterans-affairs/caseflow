import update from 'immutability-helper';
import { ACTIONS } from '../constants';
import _ from 'lodash';
import { getWorksheetAppealsAndIssues } from '../utils';

export const newHearingIssueState = (state, action, spec) => {
  _.extend(spec, { edited: { $set: true } });

  return update(state, {
    worksheetIssues: {
      [action.payload.issueId]: spec
    }
  });
};

export const newHearingWorksheetState = (state, action, spec) => {
  _.extend(spec, { edited: { $set: true } });

  return update(state, { worksheet: spec });
};

export const hearingWorksheetReducer = function(state = {}, action = {}) {
  switch (action.type) {
  case ACTIONS.POPULATE_WORKSHEET: {
    const {
      worksheet,
      worksheetAppeals,
      worksheetIssues
    } = getWorksheetAppealsAndIssues(action.payload.worksheet);

    return update(state, {
      worksheetIssues: { $set: worksheetIssues },
      worksheetAppeals: { $set: worksheetAppeals },
      worksheet: { $set: worksheet }
    });
  }

  case ACTIONS.SET_HEARING_DAY_HEARINGS:
    return update(state, {
      hearings: { $set: action.payload.hearings }
    });

  case ACTIONS.SET_REPNAME:
    return newHearingWorksheetState(state, action, { representative_name: { $set: action.payload.repName } });

  case ACTIONS.SET_WITNESS:
    return newHearingWorksheetState(state, action, { witness: { $set: action.payload.witness } });

  case ACTIONS.SET_SUMMARY:
    return newHearingWorksheetState(state, action, { summary: { $set: action.payload.summary } });

  case ACTIONS.SET_MILITARY_SERVICE:
    return newHearingWorksheetState(state, action, {
      military_service: { $set: action.payload.militaryService }
    });
  case ACTIONS.SET_HEARING_PREPPED:
    return update(state, {
      hearings: {
        [action.payload.hearingExternalId]: {
          prepped: { $set: action.payload.prepped }
        }
      }
    });

  case ACTIONS.SET_ISSUE_NOTES:
    return newHearingIssueState(state, action, { notes: { $set: action.payload.notes } });

  case ACTIONS.SET_WORKSHEET_ISSUE_NOTES:
    return newHearingIssueState(state, action, { worksheet_notes: { $set: action.payload.notes } });

  case ACTIONS.SET_ISSUE_DISPOSITION:
    return newHearingIssueState(state, action, { disposition: { $set: action.payload.disposition } });

  case ACTIONS.SET_DESCRIPTION:
    return newHearingIssueState(state, action, { description: { $set: action.payload.description } });

  case ACTIONS.SET_REOPEN:
    return newHearingIssueState(state, action, { reopen: { $set: action.payload.reopen } });

  case ACTIONS.SET_ALLOW:
    return newHearingIssueState(state, action, { allow: { $set: action.payload.allow } });

  case ACTIONS.SET_DENY:
    return newHearingIssueState(state, action, { deny: { $set: action.payload.deny } });

  case ACTIONS.SET_REMAND:
    return newHearingIssueState(state, action, { remand: { $set: action.payload.remand } });

  case ACTIONS.SET_DISMISS:
    return newHearingIssueState(state, action, { dismiss: { $set: action.payload.dismiss } });

  case ACTIONS.SET_OMO:
    return newHearingIssueState(state, action, { omo: { $set: action.payload.omo } });

  case ACTIONS.TOGGLE_ISSUE_DELETE_MODAL:
    return newHearingIssueState(state, action, { isShowingModal: { $set: action.payload.isShowingModal } });

  case ACTIONS.ADD_ISSUE:
    return update(state, {
      worksheetIssues: { [action.payload.issue.id]: {
        $set: action.payload.issue
      } }
    });

  case ACTIONS.DELETE_ISSUE:
    return newHearingIssueState(state, action, { _destroy: { $set: true } });

  case ACTIONS.TOGGLE_WORKSHEET_SAVING:
    return update(state, { worksheetIsSaving: { $set: action.payload.saving }
    });

  case ACTIONS.SET_WORKSHEET_TIME_SAVED:
    return update(state, { worksheetTimeSaved: { $set: action.payload.timeSaved }
    });

  case ACTIONS.SET_WORKSHEET_SAVE_FAILED_STATUS:
    return update(state, {
      saveWorksheetFailed: { $set: action.payload.saveFailed }
    });

  case ACTIONS.SET_ISSUE_EDITED_FLAG_TO_FALSE:
    return update(state, {
      worksheetIssues: {
        [action.payload.issueId]: { edited: { $set: false } }
      }
    });

  case ACTIONS.SET_WORKSHEET_EDITED_FLAG_TO_FALSE:
    return update(state, {
      worksheet: { edited: { $set: false } }
    });

  default: return state;
  }
};

export default hearingWorksheetReducer;
