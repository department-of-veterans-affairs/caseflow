import * as Constants from '../constants';

export const onInitialDataLoadingFail = (value = true) => ({
  type: Constants.REQUEST_INITIAL_DATA_FAILURE,
  payload: { value }
});

export const onInitialCaseLoadingFail = (value = true) => ({
  type: Constants.REQUEST_INITIAL_CASE_FAILURE,
  payload: { value }
});

export const setLoadedVacolsId = (vacolsId) => ({
  type: Constants.SET_LOADED_APPEAL_ID,
  payload: {
    vacolsId
  }
});
