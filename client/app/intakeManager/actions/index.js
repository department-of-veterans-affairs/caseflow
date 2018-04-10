import * as Constants from '../constants';
import ApiUtil from '../../util/ApiUtil';

export const populateIntakesForReview = (intakes) => ({
  type: Constants.POPULATE_INTAKES_FOR_REVIEW,
  payload: {
    intakes
  }
});

export const fetchIntakesForReview = () => (dispatch) => {
  dispatch({ type: Constants.SET_LOADING_STATE,
    payload: { value: true } });
  ApiUtil.get('/intake/manager/intakes_for_review').
    then((response) => {
      dispatch(populateIntakesForReview(response.body));
    });
};
