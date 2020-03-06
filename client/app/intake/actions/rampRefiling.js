import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { submitIntakeCompleteRequest, submitIntakeReviewRequest } from './intake';
import _ from 'lodash';

const analytics = true;

export const setAppealDocket = (appealDocket) => ({
  type: ACTIONS.SET_APPEAL_DOCKET,
  payload: {
    appealDocket
  },
  meta: {
    analytics: {
      label: appealDocket
    }
  }
});

export const confirmIneligibleForm = (intakeId) => (dispatch) => {
  dispatch({
    type: ACTIONS.CONFIRM_INELIGIBLE_FORM,
    meta: { analytics }
  });

  const data = {
    error_code: 'ineligible_for_higher_level_review'
  };

  return ApiUtil.patch(`/intake/${intakeId}/error`, { data }, ENDPOINT_NAMES.ERROR_INTAKE).
    then(
      () => dispatch({
        type: ACTIONS.START_NEW_INTAKE,
        meta: { analytics }
      }),
      (error) => {
        dispatch({
          type: ACTIONS.SUBMIT_ERROR_FAIL,
          meta: { analytics }
        });

        throw error;
      }
    ).
    catch((error) => error);
};

export const submitReview = (intakeId, rampRefiling) => (dispatch) => {
  dispatch({
    type: ACTIONS.SUBMIT_REVIEW_START,
    meta: { analytics }
  });

  const data = {
    option_selected: rampRefiling.optionSelected,
    receipt_date: rampRefiling.receiptDate,
    appeal_docket: rampRefiling.appealDocket
  };

  return submitIntakeReviewRequest(intakeId, { data })(dispatch);
};

export const setIssueSelected = (issueId, isSelected) => ({
  type: ACTIONS.SET_ISSUE_SELECTED,
  payload: {
    issueId,
    isSelected
  },
  meta: {
    analytics: {
      label: isSelected ? 'selected' : 'de-selected'
    }
  }
});

export const setHasIneligibleIssue = (hasIneligibleIssue) => ({
  type: ACTIONS.SET_HAS_INELIGIBLE_ISSUE,
  payload: {
    hasIneligibleIssue
  },
  meta: { analytics }
});

export const setOutsideCaseflowStepsConfirmed = (isConfirmed) => ({
  type: ACTIONS.CONFIRM_OUTSIDE_CASEFLOW_STEPS,
  payload: { isConfirmed },
  meta: {
    analytics: {
      label: isConfirmed ? 'confirmed' : 'not-confirmed'
    }
  }
});

export const processFinishError = () => ({ type: ACTIONS.PROCESS_FINISH_ERROR });

const validateSelectedIssues = (rampRefiling) =>
  rampRefiling.hasIneligibleIssue || _.some(rampRefiling.issues, 'isSelected');

export const completeIntake = (intakeId, rampRefiling) => (dispatch) => {
  let hasError = false;

  if (!rampRefiling.outsideCaseflowStepsConfirmed) {
    dispatch({
      type: ACTIONS.COMPLETE_INTAKE_STEPS_NOT_CONFIRMED,
      meta: { analytics }
    });

    hasError = true;
  }

  if (!validateSelectedIssues(rampRefiling)) {
    dispatch({
      type: ACTIONS.NO_ISSUES_SELECTED_ERROR,
      meta: { analytics }
    });

    hasError = true;
  }

  if (hasError) {
    return Promise.resolve(false);
  }

  dispatch({
    type: ACTIONS.COMPLETE_INTAKE_START,
    meta: { analytics }
  });

  const data = {
    has_ineligible_issue: rampRefiling.hasIneligibleIssue,
    issue_ids: _(rampRefiling.issues).
      filter('isSelected').
      map('id').
      value()
  };

  return submitIntakeCompleteRequest(intakeId, { data })(dispatch);
};
