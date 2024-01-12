import { ACTIONS } from '../levers/leversActionTypes';
import { update } from '../../../util/ReducerUtil';
import {
  createUpdatedLever,
  createUpdatedRadioLever,
  createUpdatedCombinationLever
} from './leversSelector';
import {
  createUpdatedLeversWithValues,
  formatLeverHistory
} from '../../utils';

// Refactor where it is used before deletion
export const initialState = {
  levers: {},
  backendLevers: [],
  historyList: [],
  changesOccurred: false,
  displayBanner: false,
  errors: [],
  isUserAcdAdmin: false
};

const leversReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.LOAD_LEVERS:
    return update(state, {
      levers: {
        $set: createUpdatedLeversWithValues(action.payload.levers),
      },
      backendLevers: {
        $set: createUpdatedLeversWithValues(action.payload.levers),
      },
      historyList: {
        $set: formatLeverHistory(action.payload.historyList)
      }
    });
  case ACTIONS.SET_USER_IS_ACD_ADMIN:
    return update(state, {
      isUserAcdAdmin: {
        $set: action.payload.isUserAcdAdmin
      }
    });
  case ACTIONS.UPDATE_BOOLEAN_LEVER:
  case ACTIONS.UPDATE_NUMBER_LEVER:
  case ACTIONS.UPDATE_TEXT_LEVER: {
    const leverGroup = createUpdatedLever(state, action);

    return {
      ...state,
      levers: {
        ...state.levers,
        [action.payload.leverGroup]: leverGroup,
      },
    };
  }
  case ACTIONS.UPDATE_COMBINATION_LEVER: {
    const leverGroup = createUpdatedCombinationLever(state, action);

    return {
      ...state,
      levers: {
        ...state.levers,
        [action.payload.leverGroup]: leverGroup,
      },
    };
  }
  case ACTIONS.UPDATE_RADIO_LEVER: {
    const leverGroup = createUpdatedRadioLever(state, action);

    return {
      ...state,
      levers: {
        ...state.levers,
        [action.payload.leverGroup]: leverGroup,
      },
    };
  }

  case ACTIONS.REVERT_LEVERS:
    return {
      ...state,
      levers: createUpdatedLeversWithValues(state.backendLevers)
    };

  case ACTIONS.HIDE_BANNER:
    return {
      ...state,
      displayBanner: false,
      errors: []
    };

  default:
    return state;
  }
};

export default leversReducer;
