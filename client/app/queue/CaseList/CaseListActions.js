import { SEARCH_ERROR_FOR } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import * as Constants from './actionTypes';
import _ from 'lodash';
import {
  onReceiveAppealDetails,
  onReceiveClaimReviewDetails
} from '../QueueActions';
import {
  prepareAppealForStore,
  prepareClaimReviewForStore
} from '../utils';

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

export const onReceiveAppealsUsingVeteranId = (appeals) => (dispatch) => {
  dispatch(onReceiveAppealDetails(prepareAppealForStore(appeals)));
  dispatch({
    type: Constants.RECEIVED_APPEALS_USING_VETERAN_ID_SUCCESS
  });
};

export const onReceiveClaimReviewsUsingVeteranId = (claimReviews) => (dispatch) => {
  dispatch(onReceiveClaimReviewDetails(prepareClaimReviewForStore(claimReviews)));
  dispatch({
    type: Constants.RECEIVED_CLAIM_REVIEWS_USING_VETERAN_ID_SUCCESS
  });
};

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

export const fetchAppealUsingBackendError = (searchQuery, error) => ({
  type: Constants.SEARCH_RESULTED_IN_ERROR,
  payload: {
    errorType: SEARCH_ERROR_FOR.BACKEND_ERROR,
    searchQuery,
    error
  }
});

export const fetchAppealsUsingVeteranId = (searchQuery) =>
  (dispatch) => new Promise((resolve, reject) => {
    if (!searchQuery.length) {
      dispatch(emptyQuerySearchAttempt());

      return reject();
    }

    const veteranId = searchQuery.replace(/\D/g, '');
    // Allow for SSNs (9 digits) as well as claims file numbers (7 or 8 digits).

    if (!veteranId.match(/\d{7,9}/)) {
      dispatch(fetchAppealUsingInvalidVeteranIdFailed(searchQuery));

      return reject();
    }

    dispatch(requestAppealUsingVeteranId());
    ApiUtil.get('/appeals', {
      headers: { 'veteran-id': veteranId }
    }).
      then((response) => {
        let isResponseEmpty;
        const returnedObject = (response.text) ? JSON.parse(response.text) : null;

        if (returnedObject) {
          isResponseEmpty = _.size(returnedObject.appeals) === 0 &&
            _.size(returnedObject.claim_reviews) === 0;
        }

        if (!returnedObject || isResponseEmpty) {
          dispatch(fetchedNoAppealsUsingVeteranId(veteranId));

          return reject();
        }

        dispatch(onReceiveAppealsUsingVeteranId(returnedObject.appeals));
        dispatch(onReceiveClaimReviewsUsingVeteranId(returnedObject.claim_reviews));

        const veteranIds = returnedObject.appeals.
          map((appeal) => appeal.attributes).
          concat(returnedObject.claim_reviews).
          map((obj) => obj.caseflow_veteran_id);

        return resolve([...new Set(veteranIds)]);
      }).
      catch((error) => {

        const backendError = _.get(error.response, 'body');

        if (backendError) {
          const errorMessage = backendError.errors[0].detail;

          dispatch(fetchAppealUsingBackendError(searchQuery, errorMessage));
        } else {
          dispatch(fetchAppealUsingVeteranIdFailed(searchQuery));
        }

        return reject();
      });
  });

export const setFetchedAllCasesFor = (caseflowVeteranId) => ({
  type: Constants.SET_FETCHED_ALL_CASES_FOR,
  payload: { caseflowVeteranId }
});
