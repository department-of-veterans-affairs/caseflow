import * as Constants from '../constants/constants';

export const populateDockets = (dockets) => ({
  type: Constants.POPULATE_DOCKETS,
  payload: {
    dockets
  }
});

export const populateWorksheet = (worksheet) => ({
  type: Constants.POPULATE_WORKSHEET,
  payload: {
    worksheet
  }
});

export const handleServerError = (err) => ({
  type: Constants.HANDLE_SERVER_ERROR,
  payload: {
    err
  }
});

export const setNotes = (hearingIndex, value, date) => ({
  type: Constants.SET_NOTES,
  payload: {
    hearingIndex,
    value,
    date
  }
});

export const setDisposition = (hearingIndex, value, date) => ({
  type: Constants.SET_DISPOSITION,
  payload: {
    hearingIndex,
    value,
    date
  }
});

export const setHoldOpen = (hearingIndex, value, date) => ({
  type: Constants.SET_HOLD_OPEN,
  payload: {
    hearingIndex,
    value,
    date
  }
});

export const setAOD = (hearingIndex, value, date) => ({
  type: Constants.SET_AOD,
  payload: {
    hearingIndex,
    value,
    date
  }
});

export const setTranscriptRequested = (hearingIndex, value, date) => ({
  type: Constants.SET_TRANSCRIPT_REQUESTED,
  payload: {
    hearingIndex,
    value,
    date
  }
});
