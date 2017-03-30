import * as Constants from '../constants/constants';
import SPECIAL_ISSUES from '../../constants/SpecialIssues';
import StringUtil from '../../util/StringUtil';

let specialIssues = function(state = getSpecialIssuesInitialState(), action) {
  switch(action.type) {
      case Constants.CHANGE_SPECIAL_ISSUE:
          let newState = Object.assign({}, state);
          newState[action.payload.specialIssue] = action.payload.value;
          return newState;
    default:
      return state;
  }
};

export let getSpecialIssuesInitialState = function(props = {}) {

    let initialState = {};

    SPECIAL_ISSUES.forEach((issue) => {

        // Check special issue boxes based on what was sent from the database
        let snakeCaseIssueSubstring =
            StringUtil.camelCaseToSnakeCase(issue.specialIssue).substring(0, 60);

        if (!props.task) {
            initialState[issue.specialIssue] = false;
        } else {
            initialState[issue.specialIssue] = props.task.appeal[snakeCaseIssueSubstring];
        }
    });

    return initialState;
};

export default specialIssues;