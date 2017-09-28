import * as Constants from '../constants/constants';

export const onProgramChange = (program, issueId, appealId) => ({
  type: Constants.SET_PROGRAM,
  payload: {
    program,
    issueId,
    appealId
  }
});

export const onIssueChange = (issue, issueId, appealId) => ({
  type: Constants.SET_ISSUE,
  payload: {
    issue,
    issueId,
    appealId
  }
});

export const onLevelsChange = (levels, issueId, appealId) => ({
  type: Constants.SET_LEVELS,
  payload: {
    levels,
    issueId,
    appealId
  }
});

export const onDescriptionChange = (description, issueId, appealId) => ({
  type: Constants.SET_DESCRIPTION,
  payload: {
    description,
    issueId,
    appealId
  }
});

export const onToggleReopen = (reopen, issueId, appealId) => ({
  type: Constants.SET_REOPEN,
  payload: {
    reopen,
    issueId,
    appealId
  }
});

export const onToggleAllow = (allow, issueId, appealId) => ({
  type: Constants.SET_ALLOW,
  payload: {
    allow,
    issueId,
    appealId
  }
});

export const onToggleDeny = (deny, issueId, appealId) => ({
  type: Constants.SET_DENY,
  payload: {
    deny,
    issueId,
    appealId
  }
});

export const onToggleRemand = (remand, issueId, appealId) => ({
  type: Constants.SET_REMAND,
  payload: {
    remand,
    issueId,
    appealId
  }
});

export const onToggleDismiss = (dismiss, issueId, appealId) => ({
  type: Constants.SET_DISMISS,
  payload: {
    dismiss,
    issueId,
    appealId
  }
});

export const onToggleVHA = (vha, issueId, appealId) => ({
  type: Constants.SET_VHA,
  payload: {
    vha,
    issueId,
    appealId
  }
});

