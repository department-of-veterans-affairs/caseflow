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
    dailyDocket: {
      [action.payload.date]: {
        [action.payload.hearingIndex]: spec
      }
    }
  });
};

export const setWorksheetPrepped = (state, action, spec, setEdited = true) => {
  if (setEdited) {
    _.extend(spec, { edited: { $set: true } });
  }

  return update(state, {
    dailyDocket: {
      [action.payload.date]: {
        $apply: (hearings) => {
          const changedHearingIndex = _.findIndex(hearings, { id: action.payload.hearingId });

          return update(hearings, {
            [changedHearingIndex]: spec
          });
        }
      }
    }
  });
};

// TODO move to issue reducer
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

const getDailyDocketKey = (state, action) => _.findKey(
  state.dailyDocket,
  (hearings) => _.some(hearings, { id: action.payload.hearingId })
);

const getHearingIndex = (state, action, dailyDocketKey) =>
  _.findIndex(state.dailyDocket[dailyDocketKey], { id: action.payload.hearingId });

export const hearingsReducers = function(state = mapDataToInitialState(), action = {}) {
  let dailyDocketKey;
  let hearingIndex;

  switch (action.type) {
  case Constants.POPULATE_UPCOMING_HEARINGS:
    return update(state, {
      upcomingHearings: { $set: action.payload.upcomingHearings }
    });

  case Constants.POPULATE_DAILY_DOCKET:
    return update(state, {
      dailyDocket: {
        [action.payload.date]: { $set: action.payload.dailyDocket }
      }
    });

  case Constants.POPULATE_WORKSHEET: {
    const worksheetAppeals = _.keyBy(action.payload.worksheet.appeals_ready_for_hearing, 'id');
    const worksheetIssues = _(worksheetAppeals).flatMap('worksheet_issues').
      keyBy('id').
      value();
    const worksheet = _.omit(action.payload.worksheet, ['appeals_ready_for_hearing']);

    return update(state, {
      worksheetIssues: { $set: worksheetIssues },
      worksheetAppeals: { $set: worksheetAppeals },
      worksheet: { $set: worksheet }
    });
  }

  case Constants.HANDLE_WORKSHEET_SERVER_ERROR:
    return update(state, {
      worksheetServerError: { $set: action.payload.err }
    });

  case Constants.HANDLE_DOCKET_SERVER_ERROR:
    return update(state, {
      docketServerError: { $set: action.payload.err }
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

  case Constants.SET_HEARING_VIEWED:
    dailyDocketKey = getDailyDocketKey(state, action);
    hearingIndex = getHearingIndex(state, action, dailyDocketKey);

    return update(state, {
      dailyDocket: {
        [dailyDocketKey]: {
          [hearingIndex]: {
            viewed_by_current_user: { $set: true }
          }
        }
      }
    });

  case Constants.SET_HEARING_PREPPED:
    return setWorksheetPrepped(state, action, { prepped: { $set: action.payload.prepped } },
      action.payload.setEdited);
  case Constants.SET_WORKSHEET_HEARING_PREPPED:
    return newHearingWorksheetState(state, action, { prepped: { $set: action.payload.prepped } });

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

  case Constants.SET_TRANSCRIPT_REQUESTED:
    return newHearingState(state, action, { transcript_requested: { $set: action.payload.transcriptRequested } });

  case Constants.SET_ISSUE_NOTES:
    return newHearingIssueState(state, action, { notes: { $set: action.payload.notes } });

  case Constants.SET_ISSUE_DISPOSITION:
    return newHearingIssueState(state, action, { disposition: { $set: action.payload.disposition } });

  case Constants.SET_DESCRIPTION:
    return newHearingIssueState(state, action, { description: { $set: action.payload.description } });

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
      worksheetIssues: { [action.payload.issue.id]: {
        $set: action.payload.issue
      } }
    });

  case Constants.DELETE_ISSUE:
    return newHearingIssueState(state, action, { _destroy: { $set: true } });

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

  case Constants.SET_WORKSHEET_SAVE_FAILED_STATUS:
    return update(state, {
      saveWorksheetFailed: { $set: action.payload.saveFailed }
    });

  case Constants.SET_EDITED_FLAG_TO_FALSE:
    return update(state, {
      dailyDocket: {
        [action.payload.date]: {
          [action.payload.index]: { edited: { $set: false } }
        }
      }
    });

  case Constants.SET_ISSUE_EDITED_FLAG_TO_FALSE:
    return update(state, {
      worksheetIssues: {
        [action.payload.issueId]: { edited: { $set: false } }
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
