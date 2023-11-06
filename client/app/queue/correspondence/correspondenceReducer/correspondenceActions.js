import { ACTIONS } from './correspondenceConstants';

export const loadCorrespondences = (correspondences) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.LOAD_CORRESPONDENCES,
      payload: {
        correspondences
      }
    });
  };

