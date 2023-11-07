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

export const updateRadioValue = (value) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_RADIO_VALUE,
      payload: value
    });
};

export const updateCheckboxs = (id, isChecked) => (dispatch) => {
  dispatch({
    type: ACTIONS.UPDATE_CHECKBOX_VALUES,
    payload: { id, isChecked },
  });
};
