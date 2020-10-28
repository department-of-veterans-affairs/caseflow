import * as Constants from './actionTypes';
import ApiUtil from '../../util/ApiUtil';
import { onReceiveAmaTasks } from '../QueueActions';
import { showSuccessMessage } from '../uiReducer/uiActions';
import { addressMTVSuccessAlert, returnToLitSupportAlert, reviewMotionToVacateSuccessAlert } from './mtvMessages';

export const submitMTVAttyReviewStarted = () => ({
  type: Constants.MTV_SUBMIT_ATTY_REVIEW
});

export const submitMTVAttyReviewSuccess = (task) => ({
  type: Constants.MTV_SUBMIT_ATTY_REVIEW_SUCCESS,
  payload: {
    ...task
  }
});

export const submitMTVAttyReviewError = (error) => ({
  type: Constants.MTV_SUBMIT_ATTY_REVIEW_ERROR,
  payload: error
});

export const submitMTVAttyReview = ({ newTask }) => {
  return async (dispatch, getState, { history }) => {
    dispatch(submitMTVAttyReviewStarted());

    const url = '/tasks';

    const data = {
      tasks: [newTask]
    };

    try {
      const res = await ApiUtil.post(url, { data });

      const { assigned_to_id: judgeId } = newTask;
      const judge = getState()?.queue?.judges?.[judgeId];

      dispatch(showSuccessMessage(reviewMotionToVacateSuccessAlert({ judge })));
      history.push('/queue');

      dispatch(submitMTVAttyReviewSuccess(res));
    } catch (error) {
      dispatch(submitMTVAttyReviewError(error));
    }
  };
};

export const submitMTVJudgeDecisionStarted = () => ({
  type: Constants.MTV_SUBMIT_JUDGE_DECISION
});

export const submitMTVJudgeDecisionSuccess = (task) => ({
  type: Constants.MTV_SUBMIT_JUDGE_DECISION_SUCCESS,
  payload: {
    ...task
  }
});

export const submitMTVJudgeDecisionError = () => ({
  type: Constants.MTV_SUBMIT_JUDGE_DECISION_ERROR
});

export const submitMTVJudgeDecision = (data, otherParams) => {
  return async (dispatch) => {
    dispatch(submitMTVJudgeDecisionStarted());

    const { history, appeal } = otherParams;

    const url = '/post_decision_motions';

    try {
      const res = await ApiUtil.post(url, { data });

      dispatch(submitMTVJudgeDecisionSuccess(res));

      dispatch(showSuccessMessage(addressMTVSuccessAlert({ data,
        appeal })));

      if (history) {
        history.push('/queue');
      }
    } catch (error) {
      dispatch(submitMTVJudgeDecisionError());
    }
  };
};

export const returnMTVToLitSupportStarted = () => ({
  type: Constants.MTV_RETURN_TO_LIT_SUPPORT
});

export const returnMTVToLitSupportSuccess = () => ({
  type: Constants.MTV_RETURN_TO_LIT_SUPPORT_SUCCESS,
  payload: {}
});

export const returnMTVToLitSupportError = () => ({
  type: Constants.MTV_RETURN_TO_LIT_SUPPORT_ERROR
});

export const returnToLitSupport = (data, ownProps) => {
  return async (dispatch) => {
    dispatch(returnMTVToLitSupportStarted());

    const { history, appeal } = ownProps;

    const url = '/post_decision_motions/return';

    try {
      const res = await ApiUtil.post(url, { data });
      const {
        tasks: { data: tasks }
      } = res.body;

      dispatch(returnMTVToLitSupportSuccess());

      dispatch(showSuccessMessage(returnToLitSupportAlert({ appeal })));

      if (history) {
        history.push('/queue');
      }

      // Order is important here — this must come after the redirect
      dispatch(onReceiveAmaTasks(tasks));
    } catch (error) {
      dispatch(returnMTVToLitSupportError());
    }
  };
};
