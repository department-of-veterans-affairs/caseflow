import * as Constants from '../constants';
import { enabledSpecialIssues } from '../../constants/SpecialIssueEnabler.js';
import StringUtil from '../../util/StringUtil';

export const getSpecialIssuesInitialState = function(props = {}) {

  // TODO set disable-special-issues based on NSI being true
  let initialState = {};

  const enabled_special_issues  = enabledSpecialIssues(props.featureToggles?.specialIssuesRevamp)

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
  case Constants.CLEAR_DISABLED_SPECIAL_ISSUES: {
    return state if disabledSpecialIssues == false;

    let newState = Object.assign({}, state);

    //loop through all values and set to false
    //except NSI

    return newState;
  }
  default:
    return state;
  }
};

export default specialIssues;
