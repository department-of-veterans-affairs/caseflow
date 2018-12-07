import { ACTIONS } from './actionTypes';

export const onReceiveRegionalOffices = (regionalOffices) => ({
  type: ACTIONS.RECEIVE_REGIONAL_OFFICES,
  payload: {
    regionalOffices
  }
});

export const onRegionalOfficeChange = (regionalOffice) => ({
  type: ACTIONS.REGIONAL_OFFICE_CHANGE,
  payload: {
    regionalOffice
  }
});

export const onReceiveHearingDays = (hearingDays) => ({
  type: ACTIONS.RECEIVE_HEARING_DAYS,
  payload: {
    hearingDays
  }
});

export const onHearingDayChange = (hearingDay) => ({
  type: ACTIONS.HEARING_DAY_CHANGE,
  payload: {
    hearingDay
  }
});

export const onHearingTimeChange = (hearingTime) => ({
  type: ACTIONS.HEARING_TIME_CHANGE,
  payload: {
    hearingTime
  }
});
