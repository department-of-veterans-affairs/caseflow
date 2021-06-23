import { ACTIONS } from './actionTypes';
import ApiUtil from '../../util/ApiUtil';

export const onReceiveRegionalOffices = (regionalOffices) => ({
  type: ACTIONS.RECEIVE_REGIONAL_OFFICES,
  payload: {
    regionalOffices,
  },
});

export const onRegionalOfficeChange = (regionalOffice) => ({
  type: ACTIONS.REGIONAL_OFFICE_CHANGE,
  payload: {
    regionalOffice,
  },
});

export const onReceiveHearingDays = (hearingDays) => ({
  type: ACTIONS.RECEIVE_HEARING_DAYS,
  payload: {
    hearingDays,
  },
});

export const onFetchDropdownData = (dropdownName) => ({
  type: ACTIONS.FETCH_DROPDOWN_DATA,
  payload: {
    dropdownName,
  },
});

export const onReceiveDropdownData = (dropdownName, data) => ({
  type: ACTIONS.RECEIVE_DROPDOWN_DATA,
  payload: {
    dropdownName,
    data,
  },
});

export const onDropdownError = (dropdownName, errorMsg) => ({
  type: ACTIONS.DROPDOWN_ERROR,
  payload: {
    dropdownName,
    errorMsg,
  },
});

export const onHearingOptionalTime = (optionalTime) => ({
  type: ACTIONS.HEARING_OPTIONAL_TIME_CHANGE,
  payload: {
    optionalTime,
  },
});

export const onChangeFormData = (formName, formData) => ({
  type: ACTIONS.CHANGE_FORM_DATA,
  payload: {
    formName,
    formData,
  },
});

export const onReceiveAlerts = (alerts) => {
  const timestamp = Date.now();

  return {
    type: ACTIONS.RECEIVE_ALERTS,
    payload: {
      alerts: (alerts || []).map((alert) => ({
        ...alert,
        timestamp,
      })),
    },
  };
};

export const onReceiveTransitioningAlert = (alert, key) => ({
  type: ACTIONS.RECEIVE_TRANSITIONING_ALERT,
  payload: {
    alert,
    key,
  },
});

export const transitionAlert = (key) => ({
  type: ACTIONS.TRANSITION_ALERT,
  payload: {
    key,
  },
});

export const removeAlertsWithTimestamps = (timestamps) => ({
  type: ACTIONS.REMOVE_ALERTS_WITH_EXPIRATION,
  payload: {
    timestamps,
  },
});

export const clearAlerts = () => ({
  type: ACTIONS.CLEAR_ALERTS,
});

export const startPollingHearing = (externalId) => ({
  type: ACTIONS.START_POLLING,
  payload: {
    externalId,
    polling: true,
  },
});

export const stopPollingHearing = () => ({
  type: ACTIONS.STOP_POLLING,
  payload: {
    externalId: null,
    polling: false,
  },
});

export const setScheduledHearing = (payload) => ({
  type: ACTIONS.SET_SCHEDULE_HEARING_PAYLOAD,
  payload,
});

export const fetchScheduledHearings = (hearingDay) => (dispatch) => {
  // Dispatch the action to set the pending state for the hearing time
  dispatch({ type: ACTIONS.REQUEST_SCHEDULED_HEARINGS });

  ApiUtil.get(
    `/hearings/hearing_day/${hearingDay?.hearingId}/filled_hearing_slots`
  ).then(({ body }) => {
    dispatch({
      type: ACTIONS.SET_SCHEDULED_HEARINGS,
      payload: Object.values(
        ApiUtil.convertToCamelCase(body.filled_hearing_slots)
      ),
    });
  }).
    catch(() => {
      dispatch({
        type: ACTIONS.SET_SCHEDULED_HEARINGS,
        payload: [],
      });
    });
};
