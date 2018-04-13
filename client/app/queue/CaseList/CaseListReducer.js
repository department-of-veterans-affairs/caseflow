import * as Constants from './actionTypes';
import { SEARCH_ERROR_FOR } from '../constants';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  caseListCriteria: {
    searchQuery: ''
  },
  isRequestingAppealsUsingVeteranId: false,
  receivedAppeals: [],
  search: {
    errorType: null,
    queryResultingInError: null
  }
};

export const caseListReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.CLEAR_CASE_LIST_SEARCH:
    return initialState;
  case Constants.CLEAR_CASE_LIST_SEARCH_RESULTS:
    return update(state, {
      receivedAppeals: { $set: initialState.receivedAppeals },
      search: { $set: initialState.search }
    });
  case Constants.RECEIVED_APPEALS_USING_VETERAN_ID_FAILURE:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: initialState.isRequestingAppealsUsingVeteranId },
      search: {
        errorType: { $set: SEARCH_ERROR_FOR.UNKNOWN_SERVER_ERROR },
        queryResultingInError: { $set: action.payload.searchQuery }
      }
    });
  case Constants.RECEIVED_APPEALS_USING_VETERAN_ID_SUCCESS:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: initialState.isRequestingAppealsUsingVeteranId },
      receivedAppeals: { $set: action.payload.appeals },
      search: { $set: initialState.search }
    });
  case Constants.RECEIVED_NO_APPEALS_USING_VETERAN_ID:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: initialState.isRequestingAppealsUsingVeteranId },
      search: {
        errorType: { $set: SEARCH_ERROR_FOR.NO_APPEALS },
        queryResultingInError: { $set: action.payload.searchQuery }
      }
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
