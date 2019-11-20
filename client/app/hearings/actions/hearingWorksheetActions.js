import { ACTIONS } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { now } from '../utils';

export const populateWorksheet = (worksheet) => ({
  type: ACTIONS.POPULATE_WORKSHEET,
  payload: {
    worksheet
  }
});

export const onRepNameChange = (repName) => ({
  type: ACTIONS.SET_REPNAME,
  payload: {
    repName
  }
});

export const onWitnessChange = (witness) => ({
  type: ACTIONS.SET_WITNESS,
  payload: {
    witness
  }
});

export const setHearingPrepped = (hearingExternalId, prepped) => ({
  type: ACTIONS.SET_HEARING_PREPPED,
  payload: {
    hearingExternalId,
    prepped
  }
});

export const onMilitaryServiceChange = (militaryService) => ({
  type: ACTIONS.SET_MILITARY_SERVICE,
  payload: {
    militaryService
  }
});

export const onSummaryChange = (summary) => ({
  type: ACTIONS.SET_SUMMARY,
  payload: {
    summary
  }
});

export const toggleWorksheetSaving = (saving) => ({
  type: ACTIONS.TOGGLE_WORKSHEET_SAVING,
  payload: {
    saving
  }
});

export const setWorksheetTimeSaved = (timeSaved) => ({
  type: ACTIONS.SET_WORKSHEET_TIME_SAVED,
  payload: {
    timeSaved
  }
});

export const setWorksheetSaveFailedStatus = (saveFailed) => ({
  type: ACTIONS.SET_WORKSHEET_SAVE_FAILED_STATUS,
  payload: {
    saveFailed
  }
});

export const getHearingDayHearings = (hearings) => ({
  type: ACTIONS.SET_HEARING_DAY_HEARINGS,
  payload: {
    hearings
  }
});

export const saveWorksheet = (worksheet) => (dispatch) => {
  if (!worksheet.edited) {
    dispatch(setWorksheetTimeSaved(now()));

    return;
  }

  dispatch(toggleWorksheetSaving(true));
  dispatch(setWorksheetSaveFailedStatus(false));

  const formattedHearing = {
    military_service: worksheet.military_service,
    summary: worksheet.summary,
    witness: worksheet.witness,
    representative_name: worksheet.representative_name
  };

  ApiUtil.patch(`/hearings/${worksheet.external_id}`, { data: { hearing: formattedHearing } }).
    then(() => {
      dispatch({ type: ACTIONS.SET_WORKSHEET_EDITED_FLAG_TO_FALSE });
    },
    () => {
      dispatch(setWorksheetSaveFailedStatus(true));
      dispatch(toggleWorksheetSaving(false));
    }).
    finally(() => {
      dispatch(setWorksheetTimeSaved(now()));
      dispatch(toggleWorksheetSaving(false));
    });
};

export const setPrepped = (hearingExternalId, prepped) => (dispatch) => {
  let data = { hearing: { prepped } };

  ApiUtil.patch(`/hearings/${hearingExternalId}`, { data }).
    then(() => {
      dispatch(setHearingPrepped(hearingExternalId, prepped));
    });
};

export const onDescriptionChange = (description, issueId) => ({
  type: ACTIONS.SET_DESCRIPTION,
  payload: {
    description,
    issueId
  }
});

export const onIssueNotesChange = (notes, issueId) => ({
  type: ACTIONS.SET_ISSUE_NOTES,
  payload: {
    notes,
    issueId
  }
});

export const onEditWorksheetNotes = (notes, issueId) => ({
  type: ACTIONS.SET_WORKSHEET_ISSUE_NOTES,
  payload: {
    notes,
    issueId
  }
});

export const onIssueDispositionChange = (disposition, issueId) => ({
  type: ACTIONS.SET_ISSUE_DISPOSITION,
  payload: {
    disposition,
    issueId
  }
});

export const onToggleReopen = (reopen, issueId) => ({
  type: ACTIONS.SET_REOPEN,
  payload: {
    reopen,
    issueId
  }
});

export const onToggleAllow = (allow, issueId) => ({
  type: ACTIONS.SET_ALLOW,
  payload: {
    allow,
    issueId
  }
});

export const onToggleDeny = (deny, issueId) => ({
  type: ACTIONS.SET_DENY,
  payload: {
    deny,
    issueId
  }
});

export const onToggleRemand = (remand, issueId) => ({
  type: ACTIONS.SET_REMAND,
  payload: {
    remand,
    issueId
  }
});

export const onToggleDismiss = (dismiss, issueId) => ({
  type: ACTIONS.SET_DISMISS,
  payload: {
    dismiss,
    issueId
  }
});

export const onToggleOMO = (omo, issueId) => ({
  type: ACTIONS.SET_OMO,
  payload: {
    omo,
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
      const issue = data.body.appeal.worksheet_issues.filter((dbIssue) => {
        return outgoingIssue.vacols_sequence_id === dbIssue.vacols_sequence_id;
      })[0];

      dispatch({ type: ACTIONS.ADD_ISSUE,
        payload: { issue }
      });
    });
};

export const onDeleteIssue = (issueId) => ({
  type: ACTIONS.DELETE_ISSUE,
  payload: {
    issueId
  }
});

export const toggleIssueDeleteModal = (issueId, isShowingModal) => ({
  type: ACTIONS.TOGGLE_ISSUE_DELETE_MODAL,
  payload: {
    issueId,
    isShowingModal
  }
});

export const saveIssue = (issue) => (dispatch) => {
  let url = `/hearings/appeals/${issue.appeal_id}`;
  let data = { appeal: { worksheet_issues_attributes: [issue] } };

  if (issue.docket_name === 'hearing') {
    url = `/hearings/${issue.hearing.external_id}`;
    data = { hearing: { hearing_issue_notes_attributes: [issue] } };
  }

  ApiUtil.patch(url, { data }).
    then(() => {
      dispatch({ type: ACTIONS.SET_ISSUE_EDITED_FLAG_TO_FALSE,
        payload: { issueId: issue.id }
      });
    },
    () => {
      dispatch({ type: ACTIONS.SET_WORKSHEET_SAVE_FAILED_STATUS,
        payload: { saveFailed: true } });
    });
};
