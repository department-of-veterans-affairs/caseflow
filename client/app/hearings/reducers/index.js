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
    return update(state, {
      worksheet: { repName: { $set: action.payload.repName } }
    });

  case Constants.SET_WITNESS:
    return update(state, {
      worksheet: { witness: { $set: action.payload.witness } }
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
    return newHearingState(state, action, { addon: { $set: action.payload.addOn } });

  case Constants.SET_TRANSCRIPT_REQUESTED:
    return newHearingState(state, action, { transcript_requested: { $set: action.payload.transcriptRequested } });

  case Constants.SET_DESCRIPTIONS:
    return update(state, {
      // TODO make reusable for all issues fields
      worksheet: {
        streams: {
          appeal_0: {
            issues: {
              issue_0: {
                description: {
                  $set: action.payload.description
                }
              }
            }
          }
        }
      }
    });

  case Constants.SET_CONTENTIONS:
    return update(state, {
      worksheet: { contentions: { $set: action.payload.contentions } }
    });

  case Constants.SET_PERIODS:
    return update(state, {
      worksheet: { periods: { $set: action.payload.periods } }
    });

  case Constants.SET_EVIDENCE:
    return update(state, {
      worksheet: { evidence: { $set: action.payload.evidence } }
    });

  case Constants.SET_COMMENTS:
    return update(state, {
      worksheet: { comments: { $set: action.payload.comments } }
    });

  default: return state;
  }
};

export default hearingsReducers;


