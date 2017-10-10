import * as Constants from '../constants/constants';
import ApiUtil from '../../util/ApiUtil';

export const onProgramChange = (program, issueKey, appealKey) => ({
  type: Constants.SET_PROGRAM,
  payload: {
    program,
    issueKey,
    appealKey
  }
});

export const onNameChange = (name, issueKey, appealKey) => ({
  type: Constants.SET_NAME,
  payload: {
    name,
    issueKey,
    appealKey
  }
});

export const onLevelsChange = (levels, issueKey, appealKey) => ({
  type: Constants.SET_LEVELS,
  payload: {
    levels,
    issueKey,
    appealKey
  }
});

export const onDescriptionChange = (description, issueKey, appealKey) => ({
  type: Constants.SET_DESCRIPTION,
  payload: {
    description,
    issueKey,
    appealKey
  }
});

export const onToggleReopen = (reopen, issueKey, appealKey) => ({
  type: Constants.SET_REOPEN,
  payload: {
    reopen,
    issueKey,
    appealKey
  }
});

export const onToggleAllow = (allow, issueKey, appealKey) => ({
  type: Constants.SET_ALLOW,
  payload: {
    allow,
    issueKey,
    appealKey
  }
});

export const onToggleDeny = (deny, issueKey, appealKey) => ({
  type: Constants.SET_DENY,
  payload: {
    deny,
    issueKey,
    appealKey
  }
});

export const onToggleRemand = (remand, issueKey, appealKey) => ({
  type: Constants.SET_REMAND,
  payload: {
    remand,
    issueKey,
    appealKey
  }
});

export const onToggleDismiss = (dismiss, issueKey, appealKey) => ({
  type: Constants.SET_DISMISS,
  payload: {
    dismiss,
    issueKey,
    appealKey
  }
});

export const onToggleVHA = (vha, issueKey, appealKey) => ({
  type: Constants.SET_VHA,
  payload: {
    vha,
    issueKey,
    appealKey
  }
});

export const onAddIssue = (appealKey) => ({
  type: Constants.ADD_ISSUE,
  payload: {
    appealKey
  }
});

export const onDeleteIssue = (appealKey, issueKey) => ({
  type: Constants.DELETE_ISSUE,
  payload: {
    appealKey,
    issueKey
  }
});


export const toggleIssueDeleteModal = (appealKey, issueKey, isShowingModal) => ({
  type: Constants.TOGGLE_ISSUE_DELETE_MODAL,
  payload: {
    issueKey,
    appealKey,
    isShowingModal
  }
});

export const saveIssues = (worksheet) => ((dispatch) => {
  worksheet.appeals_ready_for_hearing.map((appeal) => {
    appeal.worksheet_issues.map((issue) => {
      ApiUtil.patch(`/hearings/appeals/${appeal.id}`, { data: { appeal: {
      worksheet_issues_attributes: [issue]} } }).
      then(() => {},
          () => {
          });
    });
  });
});

