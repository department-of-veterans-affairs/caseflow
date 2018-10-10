// shared functions between reducers
import { ACTIONS } from '../constants';
import { update } from '../../util/ReducerUtil';
import _ from 'lodash';

export const commonReducers = (state, action) => {
  let actionsMap = {};

  actionsMap[ACTIONS.TOGGLE_ADD_ISSUES_MODAL] = () => {
    return update(state, {
      $toggle: ['addIssuesModalVisible']
    });
  };

  actionsMap[ACTIONS.TOGGLE_NON_RATED_ISSUE_MODAL] = () => {
    return update(state, {
      $toggle: ['nonRatedIssueModalVisible'],
      addIssuesModalVisible: {
        $set: false
      }
    });
  };

  actionsMap[ACTIONS.TOGGLE_UNIDENTIFIED_ISSUES_MODAL] = () => {
    return update(state, {
      $toggle: ['unidentifiedIssuesModalVisible'],
      nonRatedIssueModalVisible: {
        $set: false
      }
    });
  };

  actionsMap[ACTIONS.ADD_ISSUE] = () => {
    let listOfIssues = state.addedIssues ? state.addedIssues : [];
    let addedIssues = [...listOfIssues, {
      isRated: action.payload.isRated,
      id: action.payload.issueId,
      profileDate: action.payload.profileDate,
      category: action.payload.category,
      description: action.payload.description,
      decisionDate: action.payload.decisionDate,
      notes: action.payload.notes,
      isUnidentified: action.payload.isUnidentified
    }];

    return {
      ...state,
      addedIssues,
      issueCount: addedIssues.length
    };
  };

  actionsMap[ACTIONS.REMOVE_ISSUE] = () => {
    let listOfIssues = state.addedIssues ? state.addedIssues : [];
    let issueToRemove = action.payload.issue;

    return {
      ...state,
      addedIssues: _.filter(listOfIssues, (issue) => issueToRemove.referenceId !== issue.id)
    };
  };

  return actionsMap;
};

export const applyCommonReducers = (state, action) => {
  let reducerFunc = commonReducers(state, action)[action.type];

  return reducerFunc ? reducerFunc() : state;
};
