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

export const onReceiveHearingDates = (hearingDates) => ({
  type: ACTIONS.RECEIVE_HEARING_DATES,
  payload: {
    hearingDates
  }
});

export const onHearingDateChange = (hearingDate) => ({
  type: ACTIONS.HEARING_DATE_CHANGE,
  payload: {
    hearingDate
  }
});
