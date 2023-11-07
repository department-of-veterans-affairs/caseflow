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

export const loadVetCorrespondence = (vetCorrespondences) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.LOAD_VET_CORRESPONDENCE,
      payload: {
        vetCorrespondences
      }
    });
  };

