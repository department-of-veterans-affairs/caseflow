import * as Constants from './actionTypes';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  caseListCriteria: {
    searchQuery: ''
  },
  isRequestingAppealsUsingVeteranId: false,
  search: {
    errorType: null,
    queryResultingInError: null,
    errorMessage: null
  },
  fetchedAllCasesFor: {}
};

export const caseListReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.SEARCH_RESULTED_IN_ERROR:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: initialState.isRequestingAppealsUsingVeteranId },
      search: {
        errorType: { $set: action.payload.errorType },
        queryResultingInError: { $set: action.payload.searchQuery },
        errorMessage: { $set: action.payload.error }
      }
    });
  case Constants.REQUEST_APPEAL_USING_CASE_SEARCH:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: true }
    });
  case Constants.CLEAR_CASE_LIST_SEARCH:
    return update(state, {
      caseListCriteria: { $set: initialState.caseListCriteria },
      isRequestingAppealsUsingVeteranId: { $set: initialState.isRequestingAppealsUsingVeteranId },
      search: { $set: initialState.search }
    });
  case Constants.CLEAR_CASE_LIST_SEARCH_RESULTS:
    return update(state, {
      search: { $set: initialState.search }
    });
  case Constants.RECEIVED_APPEALS_USING_VETERAN_ID_SUCCESS:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: initialState.isRequestingAppealsUsingVeteranId },
      search: { $set: initialState.search }
    });
  case Constants.SET_FETCHED_ALL_CASES_FOR:
    return update(state, {
      fetchedAllCasesFor: { $merge: { [action.payload.caseflowVeteranId]: true } }
    });
  case Constants.REQUEST_APPEAL_USING_VETERAN_ID:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: true }
    });
  case Constants.SET_CASE_LIST_SEARCH:
    return update(state, {
      caseListCriteria: {
        searchQuery: {
          $set: action.payload.searchQuery
        }
      }
    });
  default:
    return state;
  }
};

export default caseListReducer;
