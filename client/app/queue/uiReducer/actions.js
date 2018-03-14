import { ACTIONS } from './constants';

export const resetErrorMessages = () => ({
  type: ACTIONS.RESET_ERROR_MESSAGES
});

export const showErrorMessage = (messageType, errorMessage) => ({
  type: ACTIONS.SHOW_ERROR_MESSAGE,
  payload: {
    messageType,
    errorMessage
  }
});

export const hideErrorMessage = (messageType) => ({
  type: ACTIONS.HIDE_ERROR_MESSAGE,
  payload: {
    messageType
  }
});

export const highlightInvalidFormItems = (highlight) => ({
  type: ACTIONS.HIGHLIGHT_INVALID_FORM_ITEMS,
  payload: {
    highlight
  }
});

export const setSelectingJudge = (selectingJudge) => ({
  type: ACTIONS.SET_SELECTING_JUDGE,
  payload: {
    selectingJudge
  }
});

export const pushBreadcrumb = (...crumbs) => ({
  type: ACTIONS.PUSH_BREADCRUMB,
  payload: {
    crumbs: [...crumbs]
  }
});

export const resetBreadcrumbs = () => ({
  type: ACTIONS.RESET_BREADCRUMBS
});
