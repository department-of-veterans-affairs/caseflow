/*
* This global reducer is called every time a state change is
* made in the application using `.dispatch`. The state changes implemented here
* are very simple. As they get more complicated and numerous,
* these are conventionally broken out into separate "actions" files
* that would live at client/app/actions/**.js.
*/
import update from 'immutability-helper';
import * as Constants from '../constants/constants';

export const mapDataToInitialState = function(state = {}) {
  return state;
};

export const newHearingState = (state, action, spec) => {
  return update(state, {
    dockets: {
      [action.payload.date]: {
        hearings_hash: {
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

  case Constants.SET_CONTENTIONS:
    return update(state, {
      worksheet: { contentions: { $set: action.payload.contentions } }
    });

  case Constants.SET_WORKSHEET_PERIODS:
    return update(state, {
      worksheet: { worksheetPeriods: { $set: action.payload.evidence } }
    });

  case Constants.SET_EVIDENCE:
    return update(state, {
      worksheet: { evidence: { $set: action.payload.evidence } }
    });

  case Constants.SET_WORKSHEET_COMMENTS:
    return update(state, {
      worksheet: { worksheetComments: { $set: action.payload.worksheetComments } }
    });

  default: return state;
  }
};


export default hearingsReducers;
