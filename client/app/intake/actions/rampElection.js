import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { submitIntakeCompleteRequest, submitIntakeReviewRequest } from './intake';
import _ from 'lodash';

const analytics = true;

export const submitReview = (intakeId, rampElection) => (dispatch) => {
  dispatch({
    type: ACTIONS.SUBMIT_REVIEW_START,
    meta: { analytics }
  });

  const data = {
    option_selected: rampElection.optionSelected,
    receipt_date: rampElection.receiptDate
  };

  return submitIntakeReviewRequest(intakeId, { data })(dispatch);
};

export const completeIntake = (intakeId, rampElection) => (dispatch) => {
  if (!rampElection.finishConfirmed) {
    dispatch({
      type: ACTIONS.COMPLETE_INTAKE_NOT_CONFIRMED,
      meta: { analytics }
    });

    return Promise.resolve(false);
  }

  dispatch({
    type: ACTIONS.COMPLETE_INTAKE_START,
    meta: { analytics }
  });

  return submitIntakeCompleteRequest(intakeId, {})(dispatch);
};

export const confirmFinishIntake = (isConfirmed) => ({
  type: ACTIONS.CONFIRM_FINISH_INTAKE,
  payload: { isConfirmed },
  meta: {
    analytics: {
      label: isConfirmed ? 'confirmed' : 'not-confirmed'
    }
  }
});
