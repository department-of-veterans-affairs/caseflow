import * as Constants from './actionTypes';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  selectedAppealVacolsId: null,
  isRequestingAppealsUsingVeteranId: false,
  selectedAppeal: {},
  receivedAppeals: [],
  search: {
    showErrorMessage: false,
    showNoAppealsInfoMessage: false,
    noAppealsSearchQuery: ''
  },
  caseSelectCriteria: {
    searchQuery: ''
  },
  assignments: [],
  assignmentsLoaded: false
};

export const caseSelectReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.CLEAR_CASE_SELECT_SEARCH:
    return update(state, {
      caseSelectCriteria: {
        searchQuery: {
          $set: ''
        }
      },
      receivedAppeals: { $set: {} },
      selectedAppeal: { $set: {} },
      selectedAppealVacolsId: { $set: null },
      search: {
        showErrorMessage: { $set: false },
        showNoAppealsInfoMessage: { $set: false }
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
      selectedAppeal: { $set: action.payload.appeal }
    });
  case Constants.CASE_SELECT_MODAL_APPEAL_VACOLS_ID:
    return update(state, {
      selectedAppealVacolsId: { $set: action.payload.vacolsId }
    });
  case Constants.REQUEST_APPEAL_USING_VETERAN_ID:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: true }
    });
  case Constants.RECEIVED_NO_APPEALS_USING_VETERAN_ID:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: false },
      search: {
        showNoAppealsInfoMessage: { $set: true },
        showErrorMessage: { $set: false },
        noAppealsSearchQuery: {
          $set: action.payload.searchQuery
        }
      }
    });
  case Constants.RECEIVE_APPEALS_USING_VETERAN_ID_SUCCESS:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: false },
      receivedAppeals: {
        $set: action.payload.appeals
      },
      search: {
        showErrorMessage: { $set: false },
        showNoAppealsInfoMessage: { $set: false },
        noAppealsSearchQuery: {
          $set: ''
        }
      }
    });
  case Constants.RECEIVE_APPEALS_USING_VETERAN_ID_FAILURE:
    return update(state, {
      isRequestingAppealsUsingVeteranId: { $set: false },
      search: {
        showErrorMessage: { $set: true },
        showNoAppealsInfoMessage: { $set: false }
      }
    });
  case Constants.RECEIVE_ASSIGNMENTS:
    return update(state,
      {
        assignments: {
          $set: action.payload.assignments
        },
        assignmentsLoaded: {
          $set: true
        }
      });
  case Constants.SET_VIEWED_ASSIGNMENT:
    return update(state,
      {
        assignments: {
          $apply: (existingAssignments) =>
            existingAssignments.map((assignment) => ({
              ...assignment,
              viewed: assignment.vacols_id === action.payload.vacolsId ? true : assignment.viewed
            }))
        }
      });
  default:
    return state;
  }
};

export default caseSelectReducer;
