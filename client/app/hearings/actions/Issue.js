import * as Constants from '../constants/constants';

export const onDescriptionChange = (description) => ({
  type: Constants.SET_DESCRIPTION,
  payload: {
    description
  }
});

export const onToggleReopen = (reopen) => ({
  type: Constants.SET_REOPEN,
  payload: {
    reopen
  }
});

export const onToggleAllow = (allow) => ({
  type: Constants.SET_ALLOW,
  payload: {
    allow
  }
});

export const onToggleDeny = (deny) => ({
  type: Constants.SET_DENY,
  payload: {
    deny
  }
});

export const onToggleRemand = (remand) => ({
  type: Constants.SET_REMAND,
  payload: {
    remand
  }
});

export const onToggleDismiss = (dismiss) => ({
  type: Constants.SET_DISMISS,
  payload: {
    dismiss
  }
});

export const onToggleVHA = (vha) => ({
  type: Constants.SET_VHA,
  payload: {
    vha
  }
});

