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

export const submitMTVAttyReview = (data) => {
  return async (dispatch) => {
    dispatch(submitMTVAttyReviewStarted());

    const url = 'motion_to_vacate/create';

    try {
      const res = await ApiUtil.post(url, { data });

      dispatch(submitMTVAttyReviewSuccess(res));
    } catch (error) {
      dispatch(submitMTVAttyReviewError());
    }
  };
};
