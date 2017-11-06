
import * as Constants from './actionTypes';
import { update } from '../../util/ReducerUtil';

const initialState = {
  ui: {
    selectedAppealVacolsId: null,
    isRequestingAppealsUsingVeteranId: false,
    selectedAppeal: {},
    receivedAppeals: [],
    search: {
      showErrorMessage: false,
      showNoAppealsInfoMessage: false
    }
  },
  caseSelectCriteria: {
    searchQuery: ''
  }
};

const caseSelectReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.CLEAR_CASE_SELECT_SEARCH:
    return update(state, {
      caseSelectCriteria: {
        searchQuery: {
          $set: ''
        }
      },
      ui: {
        receivedAppeals: { $set: {} },
        selectedAppeal: { $set: {} },
        selectedAppealVacolsId: { $set: null },
        search: {
          showErrorMessage: { $set: false },
          showNoAppealsInfoMessage: { $set: false }
        }
      }
    });
  case Constants.SET_CASE_SELECT_SEARCH:
    return update(state, {
      caseSelectCriteria: {
        searchQuery: {
          $set: action.payload.searchQuery
        }
      }
    });
  case Constants.CASE_SELECT_APPEAL:
    return update(state, {
      ui: {
        selectedAppeal: { $set: action.payload.appeal }
      }
    });
  case Constants.CASE_SELECT_MODAL_APPEAL_VACOLS_ID:
    return update(state, {
      ui: {
        selectedAppealVacolsId: { $set: action.payload.vacolsId }
      }
    });
  case Constants.REQUEST_APPEAL_USING_VETERAN_ID:
    return update(state, {
      ui: {
        isRequestingAppealsUsingVeteranId: { $set: true }
      }
    });
  case Constants.RECEIVED_NO_APPEALS_USING_VETERAN_ID:
    return update(state, {
      ui: {
        isRequestingAppealsUsingVeteranId: { $set: false },
        search: {
          showNoAppealsInfoMessage: { $set: true },
          showErrorMessage: { $set: false }
        }
      }
    });
  case Constants.RECEIVE_APPEALS_USING_VETERAN_ID_SUCCESS:
    return update(state, {
      ui: {
        isRequestingAppealsUsingVeteranId: { $set: false },
        receivedAppeals: {
          $set: action.payload.appeals
        },
        search: {
          showErrorMessage: { $set: false },
          showNoAppealsInfoMessage: { $set: false }
        }
      }
    });
  case Constants.RECEIVE_APPEALS_USING_VETERAN_ID_FAILURE:
    return update(state, {
      ui: {
        isRequestingAppealsUsingVeteranId: { $set: false },
        search: {
          showErrorMessage: { $set: true },
          showNoAppealsInfoMessage: { $set: false }
        }
      }
    });
  default:
    return state;
  }
};

export default caseSelectReducer;
