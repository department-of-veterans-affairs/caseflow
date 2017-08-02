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

export const updateDailyDocketNotes = (prop, value) => ({
  type: Constants.UPDATE_DAILY_DOCKET_NOTES,
  payload: {
    prop,
    value
  }
});

export const updateDailyDocketAction = (prop, value) => ({
  type: Constants.UPDATE_DAILY_DOCKET_ACTION,
  payload: {
    prop,
    value
  }
});

export const updateDailyDocketTranscript = (prop, value) => ({
  type: Constants.UPDATE_DAILY_DOCKET_TRANSCRIPT,
  payload: {
    prop,
    value
  }
});
