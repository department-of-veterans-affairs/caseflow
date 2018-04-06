import * as Constants from './actionTypes';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  caseListCriteria: {
    searchQuery: ''
  },
  documentCountForVeteran: 0,
  isRequestingAppealsUsingVeteranId: false,
  receivedAppeals: [],
  search: {
    showErrorMessage: false,
    noAppealsFoundSearchQueryValue: null
  },
  shouldUseAppealSearch: false
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
      documentCountForVeteran: { $set: 0 },
      receivedAppeals: { $set: {} },
      search: {
        showErrorMessage: { $set: false },
        noAppealsFoundSearchQueryValue: { $set: null }
      }
    });
  case Constants.INCREASE_VETERAN_DOCUMENT_COUNT_BY:
    return update(state, {
      documentCountForVeteran: {
        $set: action.payload.count + state.documentCountForVeteran
      }
    });
  case Constants.RECEIVED_APPEALS_USING_VETERAN_ID_FAILURE:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: false },
      search: {
        showErrorMessage: { $set: true },
        noAppealsFoundSearchQueryValue: { $set: null }
      }
    });
  case Constants.RECEIVED_APPEALS_USING_VETERAN_ID_SUCCESS:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: false },
      receivedAppeals: {
        $set: action.payload.appeals
      },
      search: {
        showErrorMessage: { $set: false },
        noAppealsFoundSearchQueryValue: { $set: null }
      }
    });
  case Constants.RECEIVED_NO_APPEALS_USING_VETERAN_ID:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: false },
      search: {
        showErrorMessage: { $set: false },
        noAppealsFoundSearchQueryValue: {
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
  case Constants.SET_SHOULD_USE_QUEUE_SEARCH:
    return update(state, {
      shouldUseAppealSearch: { $set: action.payload.bool }
    });
  default:
    return state;
  }
};

export default caseListReducer;
