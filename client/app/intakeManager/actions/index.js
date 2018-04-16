import * as Constants from '../constants';
import ApiUtil from '../../util/ApiUtil';

export const populateFlaggedForReview = (intakes) => ({
  type: Constants.POPULATE_FLAGGED_FOR_REVIEW,
  payload: {
    intakes
  }
});

export const fetchFlaggedForReview = () => (dispatch) => {
  dispatch({ type: Constants.SET_LOADING_STATE,
    payload: { value: true } });
  ApiUtil.get('/intake/manager/flagged_for_review').
    then((response) => {
      dispatch(populateFlaggedForReview(response.body));
    });
};
