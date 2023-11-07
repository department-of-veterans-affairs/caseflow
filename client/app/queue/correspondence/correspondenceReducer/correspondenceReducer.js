import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './correspondenceConstants';

export const initialState = {
  correspondences: [],
  radioValue: '2',
  checkboxValues: {},
};

export const intakeCorrespondenceReducer = (state = initialState, action = {}) => {
  let id, isChecked;

  switch (action.type) {
  case ACTIONS.LOAD_CORRESPONDENCES:
    return update(state, {
      correspondences: {
        $set: action.payload.correspondences
      }
    });
  case ACTIONS.UPDATE_RADIO_VALUE:
    return update(state, {
      radioValue: {
        $set: action.payload.radioValue
      }
    });

  case ACTIONS.UPDATE_CHECKBOX_VALUES:
    ({ id, isChecked } = action.payload);

    return update(state, {
      checkboxValues: {
        [id]: { $set: isChecked },
      },
    });

  default:
    return state;
  }
};

export default intakeCorrespondenceReducer;
