import { ACTIONS } from './constants';

export const onFetchDropdownData = (dropdownName) => ({
  type: ACTIONS.FETCH_DROPDOWN_DATA,
  payload: {
    dropdownName
  }
});

export const onReceiveDropdownData = (dropdownName, data) => ({
  type: ACTIONS.RECEIVE_DROPDOWN_DATA,
  payload: {
    dropdownName,
    data
  }
});
