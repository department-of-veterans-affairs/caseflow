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

export const submitMTVAttyReviewError = (error) => ({
  type: Constants.MTV_SUBMIT_ATTY_REVIEW_ERROR,
  payload: error
});

export const submitMTVAttyReview = (newTask, ownProps) => {
  return async (dispatch) => {
    dispatch(submitMTVAttyReviewStarted());

    const url = '/tasks';

    const { history } = ownProps;

    const data = {
      tasks: [newTask]
    };

    try {
      const res = await ApiUtil.post(url, { data });

      if (history) {
        history.push('/queue');
      }

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

export const submitMTVJudgeDecision = (data) => {
  return async (dispatch) => {
    dispatch(submitMTVJudgeDecisionStarted());

    const url = '/post_decision_motions';

    try {
      const res = await ApiUtil.post(url, { data });

      dispatch(submitMTVJudgeDecisionSuccess(res));
    } catch (error) {
      dispatch(submitMTVJudgeDecisionError());
    }
  };
};
