import * as Constants from '../constants';
import ApiUtil from '../../util/ApiUtil';

export const populateClaimsForReview = ({ claims }) => ({
  type: Constants.POPULATE_CLAIMS_FOR_REVIEW,
  payload: {
    claims
  }
});

export const fetchClaimsForReview = () => (dispatch) => {
  dispatch({ type: Constants.SET_LOADING_STATE,
    payload: { value: true } });
  ApiUtil.get('/intake/manage/claims'). // TODO
    then((response) => {
      dispatch(populateClaimsForReview(response.body));
    });
  // dispatch(populateClaimsForReview({ veteran: 'Sally' }));
};
