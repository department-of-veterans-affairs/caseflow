import * as Constants from '../constants/constants';
import ApiUtil from '../../util/ApiUtil';
import _ from 'lodash';

export const onProgramChange = (program, issueId) => ({
  type: Constants.SET_PROGRAM,
  payload: {
    program,
    issueId
  }
});

export const onNameChange = (name, issueId) => ({
  type: Constants.SET_NAME,
  payload: {
    name,
    issueId
  }
});

export const onLevelsChange = (levels, issueId) => ({
  type: Constants.SET_LEVELS,
  payload: {
    levels,
    issueId
  }
});

export const onDescriptionChange = (description, issueId) => ({
  type: Constants.SET_DESCRIPTION,
  payload: {
    description,
    issueId
  }
});

export const onToggleReopen = (reopen, issueId) => ({
  type: Constants.SET_REOPEN,
  payload: {
    reopen,
    issueId
  }
});

export const onToggleAllow = (allow, issueId) => ({
  type: Constants.SET_ALLOW,
  payload: {
    allow,
    issueId
  }
});

export const onToggleDeny = (deny, issueId) => ({
  type: Constants.SET_DENY,
  payload: {
    deny,
    issueId
  }
});

export const onToggleRemand = (remand, issueId) => ({
  type: Constants.SET_REMAND,
  payload: {
    remand,
    issueId
  }
});

export const onToggleDismiss = (dismiss, issueId) => ({
  type: Constants.SET_DISMISS,
  payload: {
    dismiss,
    issueId
  }
});

export const onToggleVHA = (vha, issueId) => ({
  type: Constants.SET_VHA,
  payload: {
    vha,
    issueId
  }
});

export const onAddIssue = (appealId, vacolsSequenceId) => (dispatch) => {
  const outgoingIssue = {
    appeal_id: appealId,
    from_vacols: false,
    vacols_sequence_id: vacolsSequenceId
  };

  ApiUtil.patch(`/hearings/appeals/${outgoingIssue.appeal_id}`, { data: { appeal: {
    worksheet_issues_attributes: [outgoingIssue] } } }).
    then((data) => {
      const issue = JSON.parse(data.text).appeal.worksheet_issues.filter((dbIssue) => {
        return outgoingIssue.vacols_sequence_id === dbIssue.vacols_sequence_id;
      })[0];

      dispatch({ type: Constants.ADD_ISSUE,
        payload: { issue } });
    });
};

export const onDeleteIssue = (issueId) => ({
  type: Constants.DELETE_ISSUE,
  payload: {
    issueId
  }
});


export const toggleIssueDeleteModal = (issueId, isShowingModal) => ({
  type: Constants.TOGGLE_ISSUE_DELETE_MODAL,
  payload: {
    issueId,
    isShowingModal
  }
});

export const saveIssues = (worksheetIssues) => (dispatch) => {
  _.forEach(worksheetIssues, (issue) => {
    if (issue.edited) {
      ApiUtil.patch(`/hearings/appeals/${issue.appeal_id}`, { data: { appeal: {
        worksheet_issues_attributes: [issue] } } }).
        then(() => {
          dispatch({ type: Constants.SET_ISSUE_EDITED_FLAG_TO_FALSE,
            payload: { issueId: issue.id } });
        },
        () => {
          dispatch({ type: Constants.SET_WORKSHEET_SAVE_FAILED_STATUS,
            payload: { saveFailed: true } });
        });
    }
  });
};

