import * as Constants from '../constants/constants';
import ApiUtil from '../../util/ApiUtil';
import { now } from '../../hearingSchedule/utils';
import _ from 'lodash';

export const populateWorksheet = (worksheet) => ({
  type: Constants.POPULATE_WORKSHEET,
  payload: {
    worksheet
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

export const setHearingPrepped = (hearingExternalId, prepped) => ({
  type: Constants.SET_HEARING_PREPPED,
  payload: {
    hearingExternalId,
    prepped
  }
});

export const onMilitaryServiceChange = (militaryService) => ({
  type: Constants.SET_MILITARY_SERVICE,
  payload: {
    militaryService
  }
});

export const onSummaryChange = (summary) => ({
  type: Constants.SET_SUMMARY,
  payload: {
    summary
  }
});

export const toggleWorksheetSaving = (saving) => ({
  type: Constants.TOGGLE_WORKSHEET_SAVING,
  payload: {
    saving
  }
});

export const setWorksheetTimeSaved = (timeSaved) => ({
  type: Constants.SET_WORKSHEET_TIME_SAVED,
  payload: {
    timeSaved
  }
});

export const setWorksheetSaveFailedStatus = (saveFailed) => ({
  type: Constants.SET_WORKSHEET_SAVE_FAILED_STATUS,
  payload: {
    saveFailed
  }
});

export const getHearingDayHearings = (hearingDayId) => (dispatch) => {
  ApiUtil.get(`/hearings/hearing_day/${hearingDayId}`).
    then((response) => {
      dispatch({
        type: Constants.SET_HEARING_DAY_HEARINGS,
        payload: {
          hearings: _.keyBy(JSON.parse(response.text).hearing_day.hearings, 'external_id')
        }
      });
    });
};

export const saveWorksheet = (worksheet) => (dispatch) => {
  if (!worksheet.edited) {
    dispatch(setWorksheetTimeSaved(now()));

    return;
  }

  dispatch(toggleWorksheetSaving(true));
  dispatch(setWorksheetSaveFailedStatus(false));

  ApiUtil.patch(`/hearings/worksheets/${worksheet.external_id}`, { data: { worksheet } }).
    then(() => {
      dispatch({ type: Constants.SET_WORKSHEET_EDITED_FLAG_TO_FALSE });
    },
    () => {
      dispatch(setWorksheetSaveFailedStatus(true));
      dispatch(toggleWorksheetSaving(false));
    }).
    finally(() => {
      dispatch(setWorksheetTimeSaved(now()));
      dispatch(toggleWorksheetSaving(false));
    });
};

export const setPrepped = (hearingExternalId, prepped) => (dispatch) => {
  dispatch(setHearingPrepped(hearingExternalId, prepped));

  let data = { hearing: { prepped } };

  ApiUtil.patch(`/hearings/${hearingExternalId}`, { data }).
    then(() => {
      // request was successful
    },
    () => {
      // request failed, resetting value
      dispatch(setHearingPrepped(hearingExternalId, !prepped));
    });
};
