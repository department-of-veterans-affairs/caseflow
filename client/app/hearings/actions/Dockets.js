import * as Constants from '../constants/constants';
import ApiUtil from '../../util/ApiUtil';
import { CATEGORIES, ACTIONS, debounceMs } from '../analytics';
import moment from 'moment';
import { now } from '../util/DateUtil';
import { DOCKETS_TAB_INDEX_MAPPING } from '../Dockets';

export const selectDocketsPageTabIndex = (tabIndex) => ({
  type: Constants.SELECT_DOCKETS_PAGE_TAB_INDEX,
  payload: {
    tabIndex
  },
  meta: {
    analytics: {
      category: CATEGORIES.DAILY_DOCKET_PAGE,
      action: ACTIONS.OPEN_HEARINGS_TAB,
      label: DOCKETS_TAB_INDEX_MAPPING[tabIndex]
    }
  }
});

export const populateUpcomingHearings = (upcomingHearings) => ({
  type: Constants.POPULATE_UPCOMING_HEARINGS,
  payload: {
    upcomingHearings
  }
});

export const populateDailyDocket = (dailyDocket, date) => ({
  type: Constants.POPULATE_DAILY_DOCKET,
  payload: {
    dailyDocket,
    date
  }
});

export const populateWorksheet = (worksheet) => ({
  type: Constants.POPULATE_WORKSHEET,
  payload: {
    worksheet
  }
});

export const handleWorksheetServerError = (err) => ({
  type: Constants.HANDLE_WORKSHEET_SERVER_ERROR,
  payload: {
    err
  }
});

export const fetchingWorksheet = () => ({
  type: Constants.FETCHING_WORKSHEET
});

export const getWorksheet = (id) => (dispatch) => {
  dispatch(fetchingWorksheet());

  ApiUtil.get(`/hearings/${id}/worksheet.json`, { cache: true }).
    then((response) => {
      dispatch(populateWorksheet(response.body));
    }, (err) => {
      dispatch(handleWorksheetServerError(err));
    });
};

export const handleDocketServerError = (err) => ({
  type: Constants.HANDLE_DOCKET_SERVER_ERROR,
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
  },
  meta: {
    analytics: {
      category: CATEGORIES.DAILY_DOCKET_PAGE,
      debounceMs
    }
  }
});

export const setHearingPrepped = (payload, gaCategory = CATEGORIES.HEARINGS_DAYS_PAGE, submitToGA = true) => ({
  type: Constants.SET_HEARING_PREPPED,
  payload,
  ...submitToGA && {
    meta: {
      analytics: {
        category: gaCategory,
        action: ACTIONS.DOCKET_HEARING_PREPPED,
        label: payload.prepped ? 'checked' : 'unchecked'
      }
    }
  }
});

export const setDisposition = (hearingIndex, disposition, date) => ({
  type: Constants.SET_DISPOSITION,
  payload: {
    hearingIndex,
    disposition,
    date
  },
  meta: {
    analytics: {
      category: CATEGORIES.DAILY_DOCKET_PAGE,
      action: ACTIONS.DISPOSITION_SELECTED,
      label: disposition
    }
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
  },
  meta: {
    analytics: {
      category: CATEGORIES.DAILY_DOCKET_PAGE,
      action: ACTIONS.AOD_SELECTED,
      label: aod
    }
  }
});

export const setTranscriptRequested = (hearingIndex, transcriptRequested, date) => ({
  type: Constants.SET_TRANSCRIPT_REQUESTED,
  payload: {
    hearingIndex,
    transcriptRequested,
    date
  },
  meta: {
    analytics: {
      category: CATEGORIES.DAILY_DOCKET_PAGE,
      action: ACTIONS.TRANSCRIPT_REQUESTED,
      label: transcriptRequested ? 'checked' : 'unchecked'
    }
  }
});

export const onMilitaryServiceChange = (militaryService) => ({
  type: Constants.SET_MILITARY_SERVICE,
  payload: {
    militaryService
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE,
      debounceMs
    }
  }
});

export const onSummaryChange = (summary) => ({
  type: Constants.SET_SUMMARY,
  payload: {
    summary
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE,
      debounceMs
    }
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

export const setDocketTimeSaved = (timeSaved) => ({
  type: Constants.SET_DOCKET_TIME_SAVED,
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

export const saveWorksheet = (worksheet) => (dispatch) => {
  if (!worksheet.edited) {
    dispatch(setWorksheetTimeSaved(now()));

    return;
  }

  dispatch(toggleWorksheetSaving(true));
  dispatch(setWorksheetSaveFailedStatus(false));

  ApiUtil.patch(`/hearings/worksheets/${worksheet.id}`, { data: { worksheet } }).
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

export const setHearingViewed = (hearingId) => ({
  type: Constants.SET_HEARING_VIEWED,
  payload: { hearingId }
});

export const getDailyDocket = (dailyDocket, date) => (dispatch) => {
  if (!dailyDocket || !dailyDocket[date]) {
    ApiUtil.get(`/hearings/dockets/${date}`, { cache: true }).
      then((response) => {
        dispatch(populateDailyDocket(response.body, date));
      }, (err) => {
        dispatch(handleDocketServerError(err));
      });
  }
};

export const setPrepped = (hearingId, prepped, date) => (dispatch) => {
  const payload = {
    hearingId,
    prepped,
    date: moment(date).format('YYYY-MM-DD'),
    setEdited: false
  };

  dispatch(setHearingPrepped(payload,
    CATEGORIES.HEARING_WORKSHEET_PAGE));

  ApiUtil.patch(`/hearings/${hearingId}`, { data: { prepped } }).
    then(() => {
      // request was successful
    },
    () => {
      payload.prepped = !prepped;

      // request failed, resetting value
      dispatch(setHearingPrepped(payload, CATEGORIES.HEARING_WORKSHEET_PAGE, false));
    });
};

export const saveDocket = (docket, date) => (dispatch) => () => {
  const hearingsToSave = docket.filter((hearing) => hearing.edited);

  if (hearingsToSave.length === 0) {
    dispatch(setDocketTimeSaved(now()));

    return;
  }

  dispatch({
    type: Constants.TOGGLE_DOCKET_SAVING,
    payload: { saving: true }
  });
  dispatch({
    type: Constants.SET_DOCKET_SAVE_FAILED,
    payload: { saveFailed: false }
  });

  let apiRequests = [];

  hearingsToSave.forEach((hearing) => {
    const index = docket.findIndex((x) => x.id === hearing.id);
    const promise = new Promise((resolve) => {
      ApiUtil.patch(`/hearings/${hearing.id}`, { data: { hearing } }).
        then(() => {
          dispatch({ type: Constants.SET_EDITED_FLAG_TO_FALSE,
            payload: { date,
              index } });
        },
        () => {
          dispatch({ type: Constants.SET_DOCKET_SAVE_FAILED,
            payload: { saveFailed: true } });
        }).
        finally(() => {
          resolve();
        });
    });

    apiRequests.push(promise);
  });

  Promise.all(apiRequests).then(() => {
    dispatch(setDocketTimeSaved(now()));
    dispatch({
      type: Constants.TOGGLE_DOCKET_SAVING,
      payload: { saving: false }
    });
  });
};
