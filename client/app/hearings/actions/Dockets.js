import * as Constants from '../constants/constants';

/* eslint-disable no-unused-vars */
/* eslint-disable no-eval */
export let lastChangeTimestamp = null;

export const updateHearing = (action, milliseconds = 1000) =>
  (dispatch, getState) => {

    dispatch(action);

    lastChangeTimestamp = Number(new Date());

    // create a function that, after a moment (default 1000ms),
    // checks if there haven't been any more calls to updateHearing().
    // If true (meaning the time at which the function runs matches
    // the time at which it was created), save the new data.

    eval(`
      setTimeout(() => {
        if (${lastChangeTimestamp} === lastChangeTimestamp) {
          dispatch({type:'TOGGLE_SAVING'});
          saveData(getState().dockets, dispatch);
        }
      }, ${milliseconds});`
    );

    // filter out edited:true + send only those to server?
  };
/* eslint-enable no-unused-vars */
/* eslint-enable no-eval */

export const saveData = (data, dispatch) => {
  setTimeout(() => {
    dispatch({
      type: 'TOGGLE_SAVING'
    });
  }, 1000);
};

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

export const onRepNameChange = (repName) => ({
  type: Constants.SET_REPNAME,
  payload: {
    repName
  }
});

export const onWitnessChange = (witness) => ({
  type: Constants.SET_WITNESS,
  payload: {
    witness
  }
});

export const setNotes = (hearingIndex, notes, date) => updateHearing({
  type: Constants.SET_NOTES,
  payload: {
    hearingIndex,
    notes,
    date
  }
});

export const setDisposition = (hearingIndex, disposition, date) => updateHearing({
  type: Constants.SET_DISPOSITION,
  payload: {
    hearingIndex,
    disposition,
    date
  }
});

export const setHoldOpen = (hearingIndex, holdOpen, date) => updateHearing({
  type: Constants.SET_HOLD_OPEN,
  payload: {
    hearingIndex,
    holdOpen,
    date
  }
});

export const setAod = (hearingIndex, aod, date) => updateHearing({
  type: Constants.SET_AOD,
  payload: {
    hearingIndex,
    aod,
    date
  }
});

export const setAddOn = (hearingIndex, addOn, date) => updateHearing({
  type: Constants.SET_ADD_ON,
  payload: {
    hearingIndex,
    addOn,
    date
  }
});

export const setTranscriptRequested = (hearingIndex, transcriptRequested, date) => updateHearing({
  type: Constants.SET_TRANSCRIPT_REQUESTED,
  payload: {
    hearingIndex,
    transcriptRequested,
    date
  }
});

export const onContentionsChange = (contentions) => ({
  type: Constants.SET_CONTENTIONS,
  payload: {
    contentions
  }
});

export const onPeriodsChange = (periods) => ({
  type: Constants.SET_PERIODS,
  payload: {
    periods
  }
});

export const onEvidenceChange = (evidence) => ({
  type: Constants.SET_EVIDENCE,
  payload: {
    evidence
  }
});

export const onCommentsChange = (comments) => ({
  type: Constants.SET_COMMENTS,
  payload: {
    comments
  }
});

/* eslint-disable no-unused-vars */
export const saveHearingsBeforeWindowCloses = () => (dispatch, getState) => {
  const dockets = getState().dockets;
};
/* eslint-enable no-unused-vars */
