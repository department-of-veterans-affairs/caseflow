/*
* This global reducer is called every time a state change is
* made in the application using `.dispatch`. The state changes implemented here
* are very simple. As they get more complicated and numerous,
* these are conventionally broken out into separate "actions" files
* that would live at client/app/actions/**.js.
*/
import update from 'immutability-helper';
import * as Constants from '../constants/constants';
import _ from 'lodash';

export const mapDataToInitialState = function(state = {}) {
  return state;
};

export const newHearingState = (state, action, spec) => {
  _.extend(spec, { edited: { $set: true } });

  return update(state, {
    dockets: {
      [action.payload.date]: {
        hearings_array: {
          [action.payload.hearingIndex]: spec
        }
      }
    }
  });
};

// TODO move to issue reducer
export const newHearingIssueState = (state, action, spec) => {
  _.extend(spec, { edited: { $set: true } });

  return update(state, {
    worksheet: {
      appeals_ready_for_hearing: {
        [action.payload.appealKey]: {
          worksheet_issues: {
            [action.payload.issueKey]: spec
          }
        }
      }
    }
  });
};

export const newHearingWorksheetState = (state, action, spec) => {
  _.extend(spec, { edited: { $set: true } });

  return update(state, { worksheet: spec });
};

export const hearingsReducers = function(state = mapDataToInitialState(), action = {}) {
  switch (action.type) {
  case Constants.POPULATE_DOCKETS:
    return update(state, {
      dockets: { $set: action.payload.dockets }
    });

  case Constants.POPULATE_WORKSHEET:
    return update(state, {
      worksheet: { $set: action.payload.worksheet }
    });

  case Constants.HANDLE_SERVER_ERROR:
    return update(state, {
      serverError: { $set: action.payload.err }
    });

  case Constants.SET_REPNAME:
    return newHearingWorksheetState(state, action, { representative_name: { $set: action.payload.repName } });

  case Constants.SET_WITNESS:
    return newHearingWorksheetState(state, action, { witness: { $set: action.payload.witness } });

  case Constants.SET_CONTENTIONS:
    return newHearingWorksheetState(state, action, { contentions: { $set: action.payload.contentions } });

  case Constants.SET_MILITARY_SERVICE:
    return newHearingWorksheetState(state, action, {
      military_service: { $set: action.payload.militaryService }
    });

  case Constants.SET_EVIDENCE:
    return newHearingWorksheetState(state, action, {
      evidence: { $set: action.payload.evidence }
    });

  case Constants.SET_COMMENTS_FOR_ATTORNEY:
    return newHearingWorksheetState(state, action, {
      comments_for_attorney: { $set: action.payload.commentsForAttorney }
    });

  case Constants.SET_NOTES:
    return newHearingState(state, action, { notes: { $set: action.payload.notes } });

  case Constants.SET_DISPOSITION:
    return newHearingState(state, action, { disposition: { $set: action.payload.disposition } });

  case Constants.SET_HOLD_OPEN:
    return newHearingState(state, action, { hold_open: { $set: action.payload.holdOpen } });

  case Constants.SET_AOD:
    return newHearingState(state, action, { aod: { $set: action.payload.aod } });

  case Constants.SET_ADD_ON:
    return newHearingState(state, action, { add_on: { $set: action.payload.addOn } });

  case Constants.SET_TRANSCRIPT_REQUESTED:
    return newHearingState(state, action, { transcript_requested: { $set: action.payload.transcriptRequested } });

  case Constants.SET_DESCRIPTION:
    return newHearingIssueState(state, action, { description: { $set: action.payload.description } });

  case Constants.SET_PROGRAM:
    return newHearingIssueState(state, action, { program: { $set: action.payload.program } });

  case Constants.SET_NAME:
    return newHearingIssueState(state, action, { name: { $set: action.payload.name } });

  case Constants.SET_LEVELS:
    return newHearingIssueState(state, action, { levels: { $set: action.payload.levels } });

  case Constants.SET_REOPEN:
    return newHearingIssueState(state, action, { reopen: { $set: action.payload.reopen } });

  case Constants.SET_ALLOW:
    return newHearingIssueState(state, action, { allow: { $set: action.payload.allow } });

  case Constants.SET_DENY:
    return newHearingIssueState(state, action, { deny: { $set: action.payload.deny } });

  case Constants.SET_REMAND:
    return newHearingIssueState(state, action, { remand: { $set: action.payload.remand } });

  case Constants.SET_DISMISS:
    return newHearingIssueState(state, action, { dismiss: { $set: action.payload.dismiss } });

  case Constants.SET_VHA:
    return newHearingIssueState(state, action, { vha: { $set: action.payload.vha } });

  case Constants.TOGGLE_ISSUE_DELETE_MODAL:
    return newHearingIssueState(state, action, { isShowingModal: { $set: action.payload.isShowingModal } });

  case Constants.ADD_ISSUE:
    return update(state, {
      worksheet: {
        appeals_ready_for_hearing: {
          [action.payload.appealKey]: {
            worksheet_issues: { $push: [{ from_vacols: false,
              edited: true }] }
          }
        }
      }
    });

  case Constants.DELETE_ISSUE:
    return newHearingIssueState(state, action, { destroyed: { $set: true } });

  case Constants.TOGGLE_DOCKET_SAVING:
    return update(state, { docketIsSaving: { $set: !state.isSaving }
    });

  case Constants.TOGGLE_WORKSHEET_SAVING:
    return update(state, { worksheetIsSaving: { $set: !state.isSaving }
    });

  case Constants.SET_DOCKET_SAVE_FAILED:
    return update(state, {
      saveDocketFailed: { $set: action.payload.saveFailed }
    });

  case Constants.SET_WORKSHEET_SAVE_FAILED:
    return update(state, {
      saveWorksheetFailed: { $set: action.payload.saveFailed }
    });

  case Constants.SET_EDITED_FLAG_TO_FALSE:
    return update(state, {
      dockets: {
        [action.payload.date]: {
          hearings_array: {
            [action.payload.index]: { edited: { $set: false } }
          }
        }
      }
    });

  case Constants.SET_ISSUE_EDITED_FLAG_TO_FALSE:
    return update(state, {
      worksheet: {
        appeals_ready_for_hearing: {
          [action.payload.appealIndex]: {
            worksheet_issues: {
              [action.payload.issueIndex]: { edited: { $set: false } }
            }
          }
        }
      }
    });

  case Constants.SET_WORKSHEET_EDITED_FLAG_TO_FALSE:
    return update(state, {
      worksheet: { edited: { $set: false } }
    });

  default: return state;
  }
};

export default hearingsReducers;
