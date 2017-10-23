// TODO move to issue reducer

import update from 'immutability-helper';
import * as Constants from '../constants/constants';
import _ from 'lodash';

export const mapDataToInitialState = function(state = {}) {
  return state;
};

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

export const hearingsIssueReducers = function(state = mapDataToInitialState(), action = {}) {
  switch (action.type) {
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
              edited: true,
              vacols_sequence_id: action.payload.vacolsSequenceId }] }
          }
        }
      }
    });

  case Constants.SET_ISSUE_ID:
    return update(state, {
      worksheet: {
        appeals_ready_for_hearing: {
          [action.payload.appealIndex]: {
            worksheet_issues: {
              [action.payload.issueIndex]: {
                id: { $set: action.payload.id }
              }
            }
          }
        }
      }
    });

  case Constants.DELETE_ISSUE:
    return newHearingIssueState(state, action, { _destroy: { $set: true } });


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

  default: return state;
  }
};

export default hearingsIssueReducers;
