import * as Constants from '../constants/constants';
import ApiUtil from '../../util/ApiUtil';
import { CATEGORIES, debounceMs } from '../analytics';
import moment from 'moment';

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

export const getWorksheet = (id) => (dispatch) => {
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

export const setHearingPrepped = (hearingId, prepped, date, setEdited) => ({
  type: Constants.SET_HEARING_PREPPED,
  payload: {
    hearingId,
    prepped,
    date,
    setEdited
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
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE,
      debounceMs
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

export const onEvidenceChange = (evidence) => ({
  type: Constants.SET_EVIDENCE,
  payload: {
    evidence
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE,
      debounceMs
    }
  }
});

export const onCommentsForAttorneyChange = (commentsForAttorney) => ({
  type: Constants.SET_COMMENTS_FOR_ATTORNEY,
  payload: {
    commentsForAttorney
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE,
      debounceMs
    }
  }
});

export const toggleWorksheetSaving = () => ({
  type: Constants.TOGGLE_WORKSHEET_SAVING
});

export const setWorksheetSaveFailedStatus = (saveFailed) => ({
  type: Constants.SET_WORKSHEET_SAVE_FAILED_STATUS,
  payload: {
    saveFailed
  }
});

export const saveWorksheet = () => (dispatch, getState) => {

  const { worksheet } = getState();

  if (!worksheet.edited) {
    return;
  }

  dispatch(toggleWorksheetSaving());
  dispatch(setWorksheetSaveFailedStatus(false));

  ApiUtil.patch(`/hearings/worksheets/${worksheet.id}`, { data: { worksheet } }).
    then(() => {
      dispatch({ type: Constants.SET_WORKSHEET_EDITED_FLAG_TO_FALSE });
    },
    () => {
      dispatch(setWorksheetSaveFailedStatus(true));
    }).
    finally(() => {
      dispatch(toggleWorksheetSaving());
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

  ApiUtil.patch(`/hearings/${hearingId}`, { data: { prepped } }).
    then((response) => {
      dispatch(setHearingPrepped(hearingId, response.body.prepped,
        moment(date).format('YYYY-MM-DD'), false));
    },
    () => {
      // we need better error handling here
      // eslint-disable-next-line no-console
      console.log('Prepped save failed');
    });
};

export const saveDocket = (docket, date) => (dispatch) => {
  const hearingsToSave = docket.filter((hearing) => hearing.edited);

  if (hearingsToSave.length === 0) {
    return;
  }

  dispatch({ type: Constants.TOGGLE_DOCKET_SAVING });

  dispatch({ type: Constants.SET_DOCKET_SAVE_FAILED,
    payload: { saveFailed: false } });

  hearingsToSave.forEach((hearing) => {

    const index = docket.findIndex((x) => x.id === hearing.id);

    ApiUtil.patch(`/hearings/${hearing.id}`, { data: { hearing } }).
      then(() => {
        dispatch({ type: Constants.SET_EDITED_FLAG_TO_FALSE,
          payload: { date,
            index } });
      },
      () => {
        dispatch({ type: Constants.SET_DOCKET_SAVE_FAILED,
          payload: { saveFailed: true } });
      });
  });
  dispatch({ type: Constants.TOGGLE_DOCKET_SAVING });
};
