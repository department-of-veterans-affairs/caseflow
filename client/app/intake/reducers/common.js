// shared functions between reducers
import { ACTIONS } from '../constants';
import { update } from '../../util/ReducerUtil';

export const commonReducers = (state, action) => {
  let actionsMap = {};

  actionsMap[ACTIONS.TOGGLE_ADD_ISSUES_MODAL] = () => {
    return update(state, {
      $toggle: ['addIssuesModalVisible']
    });
  };

  actionsMap[ACTIONS.TOGGLE_NONRATING_REQUEST_ISSUE_MODAL] = () => {
    return update(state, {
      $toggle: ['nonRatingRequestIssueModalVisible'],
      addIssuesModalVisible: {
        $set: false
      }
    });
  };

  actionsMap[ACTIONS.TOGGLE_LEGACY_OPT_IN_MODAL] = () => {
    return update(state, {
      $toggle: ['legacyOptInModalVisible'],
      addIssuesModalVisible: {
        $set: false
      },
      currentIssueAndNotes: {
        $set: action.payload.currentIssueAndNotes
      }
    });
  };

  actionsMap[ACTIONS.TOGGLE_ISSUE_REMOVE_MODAL] = () => {
    return update(state, {
      $toggle: ['removeIssueModalVisible']
    });
  };

  actionsMap[ACTIONS.TOGGLE_UNIDENTIFIED_ISSUES_MODAL] = () => {
    return update(state, {
      $toggle: ['unidentifiedIssuesModalVisible'],
      nonRatingRequestIssueModalVisible: {
        $set: false
      }
    });
  };

  actionsMap[ACTIONS.TOGGLE_UNTIMELY_EXEMPTION_MODAL] = () => {
    return update(state, {
      $toggle: ['untimelyExemptionModalVisible'],
      addIssuesModalVisible: {
        $set: false
      },
      nonRatingRequestIssueModalVisible: {
        $set: false
      },
      currentIssueAndNotes: {
        $set: action.payload.currentIssueAndNotes
      }
    });
  };

  actionsMap[ACTIONS.ADD_ISSUE] = () => {
    let listOfIssues = state.addedIssues ? state.addedIssues : [];
    let addedIssues = [...listOfIssues, action.payload];

    return {
      ...state,
      addedIssues,
      issueCount: addedIssues.length
    };
  };

  actionsMap[ACTIONS.REMOVE_ISSUE] = () => {
    // issues are removed by position, because not all issues have referenceIds
    let listOfIssues = state.addedIssues ? state.addedIssues : [];

    listOfIssues.splice(action.payload.index, 1);

    return {
      ...state,
      addedIssues: listOfIssues
    };
  };

  return actionsMap;
};

export const applyCommonReducers = (state, action) => {
  let reducerFunc = commonReducers(state, action)[action.type];

  return reducerFunc ? reducerFunc() : state;
};
