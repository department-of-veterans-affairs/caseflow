import * as Constants from '../constants';
import { enabledSpecialIssues } from '../../constants/SpecialIssueEnabler.js';
import StringUtil from '../../util/StringUtil';

export const getSpecialIssuesInitialState = function(props = {}) {

  let initialState = {};

  const enabled_special_issues  = enabledSpecialIssues(props.featureToggles?.special_issues_revamp)

  enabled_special_issues.forEach((issue) => {

    // Check special issue boxes based on what was sent from the database
    let snakeCaseIssueSubstring =
      StringUtil.camelCaseToSnakeCase(issue.specialIssue).substring(0, 60);

    if (props.task) {
      initialState[issue.specialIssue] =
        props.task.appeal[snakeCaseIssueSubstring] || false;
    } else {
      initialState[issue.specialIssue] = false;
    }
  });

  return initialState;
};

let specialIssues = function(state = getSpecialIssuesInitialState(), action) {
  switch (action.type) {
  case Constants.CHANGE_SPECIAL_ISSUE: {
    let newState = Object.assign({}, state);

    newState[action.payload.specialIssue] = action.payload.value;

    return newState;
  }
  default:
    return state;
  }
};

export default specialIssues;
