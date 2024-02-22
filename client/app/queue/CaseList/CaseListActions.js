import { SEARCH_ERROR_FOR } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import * as Constants from './actionTypes';

import { get, size } from 'lodash';
import { onReceiveAppealDetails, onReceiveClaimReviewDetails } from '../QueueActions';
import { prepareAppealForSearchStore, prepareClaimReviewForStore } from '../utils';
import ValidatorsUtil from '../../util/ValidatorsUtil';

const { validSSN, validFileNum, validDocketNum } = ValidatorsUtil;

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

export const requestAppealUsingCaseSearch = () => ({
  type: Constants.REQUEST_APPEAL_USING_CASE_SEARCH
});

export const emptyQuerySearchAttempt = () => ({
  type: Constants.SEARCH_RESULTED_IN_ERROR,
  payload: {
    errorType: SEARCH_ERROR_FOR.EMPTY_SEARCH_TERM,
    searchQuery: ''
  }
});

export const fetchedNoAppeals = (searchQuery) => ({
  type: Constants.SEARCH_RESULTED_IN_ERROR,
  payload: {
    errorType: SEARCH_ERROR_FOR.NO_APPEALS,
    searchQuery
  }
});

export const onReceiveAppeals = (appeals) => (dispatch) => {
  dispatch(onReceiveAppealDetails(prepareAppealForSearchStore(appeals)));
  dispatch({
    type: Constants.RECEIVED_APPEALS_USING_VETERAN_ID_SUCCESS
  });
};

export const onReceiveClaimReviews = (claimReviews) => (dispatch) => {
  dispatch(onReceiveClaimReviewDetails(prepareClaimReviewForStore(claimReviews)));
  dispatch({
    type: Constants.RECEIVED_CLAIM_REVIEWS_USING_VETERAN_ID_SUCCESS
  });
};

export const fetchAppealFromSearchFailed = (searchQuery) => ({
  type: Constants.SEARCH_RESULTED_IN_ERROR,
  payload: {
    errorType: SEARCH_ERROR_FOR.UNKNOWN_SERVER_ERROR,
    searchQuery
  }
});

export const invalidCaseSearchTerm = (searchQuery) => ({
  type: Constants.SEARCH_RESULTED_IN_ERROR,
  payload: {
    errorType: SEARCH_ERROR_FOR.INVALID_VETERAN_ID,
    searchQuery
  }
});

export const caseSearchBackendError = (searchQuery, error) => ({
  type: Constants.SEARCH_RESULTED_IN_ERROR,
  payload: {
    errorType: SEARCH_ERROR_FOR.BACKEND_ERROR,
    searchQuery,
    error
  }
});

const uniqueVetIdsFromCases = ({ appeals, claim_reviews }) => {
  const veteranIds = appeals.
    map((appeal) => appeal.attributes).
    concat(claim_reviews).
    map((obj) => obj.caseflow_veteran_id);

  return [...new Set(veteranIds)];
};

export const fetchAppealsBySearch = (searchTerm) => (dispatch) => {
  return ApiUtil.get('/appeals', { headers: { 'case-search': searchTerm } }).
    then((response) => {
      const returnedObject = response.text ? JSON.parse(response.text) : null;
      const isResponseEmpty = returnedObject && !size(returnedObject.appeals) && !size(returnedObject.claim_reviews);

      if (!returnedObject || isResponseEmpty) {
        dispatch(fetchedNoAppeals(searchTerm));

        return Promise.reject();
      }

      dispatch(onReceiveAppeals(returnedObject.appeals));
      dispatch(onReceiveClaimReviews(returnedObject.claim_reviews));

      // Return with duplicates removed
      return uniqueVetIdsFromCases(returnedObject);
    }).
    catch((error) => {
      const backendError = get(error.response, 'body');

      if (backendError) {
        const errorMessage = backendError.errors[0].detail;

        dispatch(caseSearchBackendError(searchTerm, errorMessage));
      } else {
        dispatch(fetchAppealFromSearchFailed(searchTerm));
      }

      return Promise.reject();
    });
};

export const appealsSearch = (searchQuery) => async (dispatch) => {
  if (!searchQuery.length) {
    dispatch(emptyQuerySearchAttempt());

    return Promise.reject();
  }

  // Allow numbers + hyphen (for docket number)
  const searchTerm = searchQuery.trim().replace(/[^\d-]/g, '');

  const validInput = (i) => validSSN(i) || validFileNum(i) || validDocketNum(i);

  if (!validInput(searchTerm)) {
    dispatch(invalidCaseSearchTerm(searchQuery));

    return Promise.reject();
  }

  dispatch(requestAppealUsingCaseSearch());

  return await dispatch(fetchAppealsBySearch(searchTerm));
};

export const setFetchedAllCasesFor = (caseflowVeteranId) => ({
  type: Constants.SET_FETCHED_ALL_CASES_FOR,
  payload: { caseflowVeteranId }
});
