import ApiUtil from '../../util/ApiUtil';
import * as Constants from './actionTypes';
import _ from 'lodash';

export const clearCaseListSearch = () => ({
  type: Constants.CLEAR_CASE_LIST_SEARCH
});

export const clearCaseListSearchResults = () => ({
  type: Constants.CLEAR_CASE_LIST_SEARCH_RESULTS
});

export const setCaseListSearch = (searchQuery) => ({
  type: Constants.SET_CASE_LIST_SEARCH,
  payload: { searchQuery }
});

export const requestAppealUsingVeteranId = () => ({
  type: Constants.REQUEST_APPEAL_USING_VETERAN_ID
});

export const fetchedNoAppealsUsingVeteranId = (searchQuery) => ({
  type: Constants.RECEIVED_NO_APPEALS_USING_VETERAN_ID,
  payload: { searchQuery }
});

export const onReceiveAppealsUsingVeteranId = (appeals) => ({
  type: Constants.RECEIVED_APPEALS_USING_VETERAN_ID_SUCCESS,
  payload: { appeals }
});

export const fetchAppealUsingVeteranIdFailed = (searchQuery) => ({
  type: Constants.RECEIVED_APPEALS_USING_VETERAN_ID_FAILURE,
  payload: { searchQuery }
});

export const fetchAppealUsingInvalidVeteranIdFailed = (searchQuery) => ({
  type: Constants.APPEALS_FETCH_FAILED_INVALID_VETERAN_ID,
  payload: { searchQuery }
});

export const fetchAppealsUsingVeteranId = (searchQuery) =>
  (dispatch) => {
    const veteranId = searchQuery.replace(/\D/g, '');
    // Allow for SSNs (9 digits) as well as claims file numbers (7 or 8 digits).

    if (!veteranId.match(/\d{7,9}/)) {
      dispatch(fetchAppealUsingInvalidVeteranIdFailed(veteranId));

      return;
    }

    dispatch(requestAppealUsingVeteranId());
    ApiUtil.get('/appeals', {
      headers: { 'veteran-id': veteranId }
    }).
      then((response) => {
        const returnedObject = JSON.parse(response.text);

        if (_.size(returnedObject.appeals) === 0) {
          dispatch(fetchedNoAppealsUsingVeteranId(veteranId));
        } else {
          dispatch(onReceiveAppealsUsingVeteranId(returnedObject.appeals));
        }
      }, () => {
        dispatch(fetchAppealUsingVeteranIdFailed(veteranId));
      });
  };
