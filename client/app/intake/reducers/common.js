// shared functions between reducers
import { ACTIONS } from '../constants';
import { update } from '../../util/ReducerUtil';

export const commonReducers = (state, action) => {
  let actionsMap = {};
  let listOfIssues = state.addedIssues ? state.addedIssues : [];

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
      nonRatingRequestIssueModalVisible: {
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
      legacyOptInModalVisible: {
        $set: false
      },
      currentIssueAndNotes: {
        $set: action.payload.currentIssueAndNotes
      }
    });
  };

  actionsMap[ACTIONS.ADD_ISSUE] = () => {
    let addedIssues = [...listOfIssues, action.payload];

    return {
      ...state,
      addedIssues,
      issueCount: addedIssues.length
    };
  };

  actionsMap[ACTIONS.REMOVE_ISSUE] = () => {
    // issues are removed by position, because not all issues have referenceIds
    listOfIssues.splice(action.payload.index, 1);

    return {
      ...state,
      addedIssues: listOfIssues
    };
  };

  actionsMap[ACTIONS.WITHDRAW_ISSUE] = () => {
    listOfIssues[action.payload.index].withdrawalPending = true;

    return {
      ...state,
      addedIssues: listOfIssues
    };
  };

  actionsMap[ACTIONS.SET_ISSUE_WITHDRAWAL_DATE] = () => {
    return {
      ...state,
      withdrawalDate: action.payload.withdrawalDate
    };
  };

  actionsMap[ACTIONS.CORRECT_ISSUE] = () => {
    listOfIssues[action.payload.index].correctionType = 'control';

    return {
      ...state,
      addedIssues: listOfIssues
    };
  };

  actionsMap[ACTIONS.UNDO_CORRECTION] = () => {
    delete listOfIssues[action.payload.index].correctionType;

    return {
      ...state,
      addedIssues: listOfIssues
    };
  };

  actionsMap[ACTIONS.SET_EDIT_CONTENTION_TEXT] = () => {
    listOfIssues[action.payload.issueIdx].editedDescription = action.payload.editedDescription;

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
