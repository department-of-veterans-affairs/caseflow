import * as Constants from './actionTypes';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  caseListCriteria: {
    searchQuery: ''
  },
  displayCaseListResults: false,
  isRequestingAppealsUsingVeteranId: false,
  receivedAppeals: [],
  search: {
    showErrorMessage: false,
    queryResultingInError: null
  }
};

export const caseListReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.CLEAR_CASE_LIST_SEARCH:
    return update(state, {
      caseListCriteria: {
        searchQuery: {
          $set: ''
        }
      },
      displayCaseListResults: { $set: false },
      receivedAppeals: { $set: {} },
      search: {
        showErrorMessage: { $set: false },
        queryResultingInError: { $set: null }
      }
    });
  case Constants.CLEAR_CASE_LIST_SEARCH_RESULTS:
    return update(state, {
      receivedAppeals: { $set: {} },
      search: {
        showErrorMessage: { $set: false },
        queryResultingInError: { $set: null }
      }
    });
  case Constants.RECEIVED_APPEALS_USING_VETERAN_ID_FAILURE:
    return update(state, {
      displayCaseListResults: { $set: true },
      isRequestingAppealsUsingVeteranId: { $set: false },
      search: {
        showErrorMessage: { $set: true },
        queryResultingInError: { $set: action.payload.searchQuery }
      }
    });
  case Constants.RECEIVED_APPEALS_USING_VETERAN_ID_SUCCESS:
    return update(state, {
      displayCaseListResults: { $set: true },
      isRequestingAppealsUsingVeteranId: { $set: false },
      receivedAppeals: {
        $set: action.payload.appeals
      },
      search: {
        showErrorMessage: { $set: false },
        queryResultingInError: { $set: null }
      }
    });
  case Constants.RECEIVED_NO_APPEALS_USING_VETERAN_ID:
    return update(state, {
      displayCaseListResults: { $set: true },
      isRequestingAppealsUsingVeteranId: { $set: false },
      search: {
        showErrorMessage: { $set: false },
        queryResultingInError: {
          $set: action.payload.searchQuery
        }
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
