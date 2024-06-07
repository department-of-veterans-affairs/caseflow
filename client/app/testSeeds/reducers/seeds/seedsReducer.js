import { ACTIONS } from '../seeds/seedsActionTypes';
import { update } from '../../../util/ReducerUtil';


// Refactor where it is used before deletion
export const initialState = {
  seeds: [],
  displayBanner: false
};

const seedsReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.ADD_CUSTOM_SEED:
    return {
      ...state,
      seeds: [...state.seeds, action.payload.seed]
    };
  case ACTIONS.REMOVE_CUSTOM_SEED:
    return {
      ...state,
      seeds: state.seeds.filter((_, index) => index !== action.payload.index)
    };
  case ACTIONS.SAVE_CUSTOM_SEEDS:
    return {
      ...state,
      displayBanner: true
    };
  case ACTIONS.RESET_CUSTOM_SEEDS:
    return {
      ...state,
      seeds: []
    };
  default:
    return state;
  }
};

export default seedsReducer;
