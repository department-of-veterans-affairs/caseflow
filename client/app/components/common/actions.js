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
