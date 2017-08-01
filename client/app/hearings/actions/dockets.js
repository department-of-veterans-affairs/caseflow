import * as Constants from '../constants/constants';
import { prepSaveData } from '../utils';
import { handleServerError } from '../actions/hearings';
import ApiUtil from '../../util/ApiUtil';
import diff from 'object-diff';

export let lastChangeTimestamp = null;
export let lastSave = {};
export const diffObjects = diff;

/* eslint-disable no-unused-vars */
/* eslint-disable no-eval */
/* eslint-disable no-console */
export const updatedState = (action, milliseconds = 1000) =>
  (dispatch, getState) => {

    dispatch(action);

    lastChangeTimestamp = Number(new Date());

    // create a function that, after a moment (default 1000ms),
    // checks if this action hasn't been dispatched again.  If
    // true (meaning the time at which the function runs matches
    // the time at which it was created), save the new data.

    eval(`
      setTimeout(() => {
        if (${lastChangeTimestamp} === lastChangeTimestamp) {
          dispatch({type:'TOGGLE_SAVING'});
          saveData(diffObjects(lastSave, getState().save), dispatch, action.payload.apiUrl);
          lastSave = getState().save;
        }
      }, ${milliseconds});`
    );

  };
/* eslint-enable no-unused-vars */
/* eslint-enable no-eval */

export const saveData = (data, dispatch, url = '/hearings/save_data') => {

  const dataToSave = prepSaveData(data);

  console.log('Saving', dataToSave, new Date());

  // Temp route action to simulate the autosave feature
  // Get the route from the action payload - backend will know what to do

  // ApiUtil.post(url, { data: { id: saveModelId, model: saveModel } }).
  ApiUtil.post(url, { data: dataToSave }).
    then(
      () => dispatch({
        type: 'TOGGLE_SAVING'
      }),
      (err) => {
        dispatch(handleServerError(err));
      }
    );
};

export const updateDailyDocketNotes = (prop, value) => {
  return updatedState({
    type: Constants.UPDATE_DAILY_DOCKET_NOTES,
    payload: {
      prop,
      value
      // apiUrl: null - TODO put real URL here
    }
  });
};

export const updateDailyDocketAction = (prop, value) => {
  return updatedState({
    type: Constants.UPDATE_DAILY_DOCKET_ACTION,
    payload: {
      prop,
      value
      // apiUrl: null - TODO put real URL here
    }
  });
};

export const updateDailyDocketTranscript = (prop, value) => {
  return updatedState({
    type: Constants.UPDATE_DAILY_DOCKET_TRANSCRIPT,
    payload: {
      prop,
      value
      // apiUrl: null - TODO put real URL here
    }
  });
};

export const populateDockets = (dockets) => ({
  type: Constants.POPULATE_DOCKETS,
  payload: {
    dockets
  }
});
