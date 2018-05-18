import { SEARCH_ERROR_FOR } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import * as Constants from './actionTypes';
import _ from 'lodash';

export const clearCaseListSearch = () => ({
  type: Constants.CLEAR_CASE_LIST_SEARCH
});

export const clearCaseListSearchResults = () => ({
  type: Constants.CLEAR_CASE_LIST_SEARCH_RESULTS
});

export const setSearchTerm = (searchQuery) => ({
  type: Constants.SET_CASE_LIST_SEARCH,
  payload: { searchQuery }
});

export const setCaseListSearch = (searchQuery) => (dispatch) => {
  dispatch(setSearchTerm(searchQuery));
  if (!searchQuery) {
    dispatch(clearCaseListSearch());
  }
};

export const requestAppealUsingVeteranId = () => ({
  type: Constants.REQUEST_APPEAL_USING_VETERAN_ID
});

export const emptyQuerySearchAttempt = () => ({
  type: Constants.SEARCH_RESULTED_IN_ERROR,
  payload: {
    errorType: SEARCH_ERROR_FOR.EMPTY_SEARCH_TERM,
    searchQuery: ''
  }
});

export const fetchedNoAppealsUsingVeteranId = (searchQuery) => ({
  type: Constants.SEARCH_RESULTED_IN_ERROR,
  payload: {
    errorType: SEARCH_ERROR_FOR.NO_APPEALS,
    searchQuery
  }
});

export const onReceiveAppealsUsingVeteranId = (appeals) => ({
  type: Constants.RECEIVED_APPEALS_USING_VETERAN_ID_SUCCESS,
  payload: { appeals }
});

export const fetchAppealUsingVeteranIdFailed = (searchQuery) => ({
  type: Constants.SEARCH_RESULTED_IN_ERROR,
  payload: {
    errorType: SEARCH_ERROR_FOR.UNKNOWN_SERVER_ERROR,
    searchQuery
  }
});

export const fetchAppealUsingInvalidVeteranIdFailed = (searchQuery) => ({
  type: Constants.SEARCH_RESULTED_IN_ERROR,
  payload: {
    errorType: SEARCH_ERROR_FOR.INVALID_VETERAN_ID,
    searchQuery
  }
});

export const fetchAppealsUsingVeteranId = (searchQuery) =>
  (dispatch) => {
    const veteranId = searchQuery.replace(/\D/g, '');
    // Allow for SSNs (9 digits) as well as claims file numbers (7 or 8 digits).

    if (!veteranId.match(/\d{7,9}/)) {
      dispatch(fetchAppealUsingInvalidVeteranIdFailed(searchQuery));

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
        dispatch(fetchAppealUsingVeteranIdFailed(searchQuery));
      });
  };
