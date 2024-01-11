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

// formattedHistory should be deleted.
// Refactor where it is used before deletion
export const initialState = {
  levers: {},
  backendLevers: [],
  formattedHistory: {},
  historyList: [],
  changesOccurred: false,
  displayBanner: false,
  errors: []
};

const leversReducer = (state = initialState, action = {}) => {
  switch (action.type) {

  case ACTIONS.INITIAL_LOAD:
    return update(state, {
      levers: {
        $set: createUpdatedLeversWithValues(action.payload.levers),
      },
      backendLevers: {
        $set: createUpdatedLeversWithValues(action.payload.levers),
      },
    });

  case ACTIONS.LOAD_LEVERS:
    return update(state, {
      levers: {
        $set: action.payload.levers
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
  // needs to be reworked; remove comment when done
  case ACTIONS.FORMAT_LEVER_HISTORY:
    return {
      ...state,
      historyList: formatLeverHistory(action.history)
    };

  case ACTIONS.SAVE_LEVERS:
    return {
      ...state,
      changesOccurred: false,
      historyList: formatLeverHistory(action.payload.leverHistory),
      displayBanner: action.payload.successful,
      errors: action.payload.errors
    };

  case ACTIONS.REVERT_LEVERS:
    return {
      ...state,
      levers: createUpdatedLeversWithValues(state.backendLevers)
    };

  case ACTIONS.HIDE_BANNER:
    return {
      ...state,
      displayBanner: false
    };

  default:
    return state;
  }
};

export default leversReducer;
