import * as Constants from '../constants/constants';
import ApiUtil from '../../util/ApiUtil';

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


export const setNotes = (hearingIndex, notes, date) => ({
  type: Constants.SET_NOTES,
  payload: {
    hearingIndex,
    notes,
    date
  }
});

export const setDisposition = (hearingIndex, disposition, date) => ({
  type: Constants.SET_DISPOSITION,
  payload: {
    hearingIndex,
    disposition,
    date
  }
});

export const setHoldOpen = (hearingIndex, holdOpen, date) => ({
  type: Constants.SET_HOLD_OPEN,
  payload: {
    hearingIndex,
    holdOpen,
    date
  }
});

export const setAod = (hearingIndex, aod, date) => ({
  type: Constants.SET_AOD,
  payload: {
    hearingIndex,
    aod,
    date
  }
});

export const setAddOn = (hearingIndex, addOn, date) => ({
  type: Constants.SET_ADD_ON,
  payload: {
    hearingIndex,
    addOn,
    date
  }
});

export const setTranscriptRequested = (hearingIndex, transcriptRequested, date) => ({
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

export const onMilitaryServiceChange = (militaryService) => ({
  type: Constants.SET_MILITARY_SERVICE,
  payload: {
    militaryService
  }
});

export const onEvidenceChange = (evidence) => ({
  type: Constants.SET_EVIDENCE,
  payload: {
    evidence
  }
});

export const onCommentsForAttorneyChange = (commentsForAttorney) => ({
  type: Constants.SET_COMMENTS_FOR_ATTORNEY,
  payload: {
    commentsForAttorney
  }
});

export const toggleWorksheetSaving = () => ({
  type: Constants.TOGGLE_WORKSHEET_SAVING
});

export const saveWorksheet = (worksheet) => ((dispatch) => {
  if (!worksheet.edited) {
    return;
  }

  dispatch({
    type: Constants.SET_WORKSHEET_SAVE_FAILED,
    payload: { saveFailed: false }
  });

  ApiUtil.patch(`/hearings/worksheets/${worksheet.id}`, { data: { worksheet } }).
  then(() => {
    dispatch({ type: Constants.SET_WORKSHEET_EDITED_FLAG_TO_FALSE });
  },
  () => {
    dispatch({ type: Constants.SET_WORKSHEET_SAVE_FAILED,
      payload: { saveFailed: true } });
  });
});
