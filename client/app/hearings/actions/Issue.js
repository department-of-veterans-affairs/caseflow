import * as Constants from '../constants/constants';

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

