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
