import * as Constants from '../constants/constants';
import ApiUtil from '../../util/ApiUtil';
import _ from 'lodash';
import { CATEGORIES, ACTIONS } from '../analytics';

export const onDescriptionChange = (description, issueId) => ({
  type: Constants.SET_DESCRIPTION,
  payload: {
    description,
    issueId
  }
});

export const onIssueNotesChange = (notes, issueId) => ({
  type: Constants.SET_ISSUE_NOTES,
  payload: {
    notes,
    issueId
  }
});

export const onIssueDispositionChange = (disposition, issueId) => ({
  type: Constants.SET_ISSUE_DISPOSITION,
  payload: {
    disposition,
    issueId
  }
});

export const onToggleReopen = (reopen, issueId) => ({
  type: Constants.SET_REOPEN,
  payload: {
    reopen,
    issueId
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE,
      action: ACTIONS.TOGGLE_PRELIMINARY_IMPRESSION,
      label: 'reopen'
    }
  }
});

export const onToggleAllow = (allow, issueId) => ({
  type: Constants.SET_ALLOW,
  payload: {
    allow,
    issueId
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE,
      action: ACTIONS.TOGGLE_PRELIMINARY_IMPRESSION,
      label: 'allow'
    }
  }
});

export const onToggleDeny = (deny, issueId) => ({
  type: Constants.SET_DENY,
  payload: {
    deny,
    issueId
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE,
      action: ACTIONS.TOGGLE_PRELIMINARY_IMPRESSION,
      label: 'deny'
    }
  }
});

export const onToggleRemand = (remand, issueId) => ({
  type: Constants.SET_REMAND,
  payload: {
    remand,
    issueId
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE,
      action: ACTIONS.TOGGLE_PRELIMINARY_IMPRESSION,
      label: 'remand'
    }
  }
});

export const onToggleDismiss = (dismiss, issueId) => ({
  type: Constants.SET_DISMISS,
  payload: {
    dismiss,
    issueId
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE,
      action: ACTIONS.TOGGLE_PRELIMINARY_IMPRESSION,
      label: 'dismiss'
    }
  }
});

export const onToggleVHA = (vha, issueId) => ({
  type: Constants.SET_VHA,
  payload: {
    vha,
    issueId
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE,
      action: ACTIONS.TOGGLE_PRELIMINARY_IMPRESSION,
      label: 'vha'
    }
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
        payload: { issue },
        meta: {
          analytics: {
            category: CATEGORIES.HEARING_WORKSHEET_PAGE
          }
        }
      });
    });
};

export const onDeleteIssue = (issueId) => ({
  type: Constants.DELETE_ISSUE,
  payload: {
    issueId
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE
    }
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
            payload: { issueId: issue.id },
            meta: {
              analytics: {
                category: CATEGORIES.HEARING_WORKSHEET_PAGE,
                action: ACTIONS.EDIT_ISSUE
              }
            }
          });
        },
        () => {
          dispatch({ type: Constants.SET_WORKSHEET_SAVE_FAILED_STATUS,
            payload: { saveFailed: true } });
        });
    }
  });
};

