import * as Constants from './actionTypes';
import ApiUtil from '../../util/ApiUtil';

export const submitMTVAttyReviewStarted = () => ({
  type: Constants.MTV_SUBMIT_ATTY_REVIEW
});

export const submitMTVAttyReviewSuccess = (task) => ({
  type: Constants.MTV_SUBMIT_ATTY_REVIEW_SUCCESS,
  payload: {
    ...task
  }
});

export const submitMTVAttyReviewError = () => ({
  type: Constants.MTV_SUBMIT_ATTY_REVIEW_ERROR
});

export const submitMTVAttyReview = (data, ownProps) => {
  return async (dispatch) => {
    dispatch(submitMTVAttyReviewStarted());

    const url = '/post_decision_motions';

    const { history } = ownProps;

    try {
      const res = await ApiUtil.post(url, { data });

      if (history) {
        history.push('/queue');
      }

      dispatch(submitMTVAttyReviewSuccess(res));
    } catch (error) {
      dispatch(submitMTVAttyReviewError());
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

export const submitMTVJudgeDecision = (data) => {
  return async (dispatch) => {
    dispatch(submitMTVJudgeDecisionStarted());

    const url = 'motion_to_vacate/create';

    try {
      const res = await ApiUtil.post(url, { data });

      dispatch(submitMTVJudgeDecisionSuccess(res));
    } catch (error) {
      dispatch(submitMTVJudgeDecisionError());
    }
  };
};
