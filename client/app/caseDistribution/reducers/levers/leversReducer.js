import { ACTIONS } from '../levers/leversActionTypes';
import { update } from '../../../util/ReducerUtil';
import {
  createUpdatedLever,
  createUpdatedRadioLever,
  createUpdatedCombinationLever
} from './leversSelector';
import {
  createUpdatedLeversWithValues,
  formatLeverHistory,
  leverErrorMessageExists
} from '../../utils';

// Refactor where it is used before deletion
export const initialState = {
  levers: {},
  historyList: [],
  displayBanner: false,
  leversErrors: [],
  errors: [],
  isUserAcdAdmin: false
};

const leversReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.LOAD_LEVERS:
    return update(state, {
      levers: {
        $set: createUpdatedLeversWithValues(action.payload.levers),
      }
    });
  case ACTIONS.LOAD_HISTORY:
    return update(state, {
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

  case ACTIONS.SAVE_LEVERS:
    return {
      ...state,
      displayBanner: true,
      errors: action.payload.errors
    };

  case ACTIONS.HIDE_BANNER:
    return {
      ...state,
      displayBanner: false,
      errors: []
    };

  case ACTIONS.ADD_LEVER_VALIDATION_ERRORS:
    return {
      ...state,
      leversErrors: leverErrorMessageExists(state.leversErrors, action.payload.errors) ?
        state.leversErrors : [...state.leversErrors, ...action.payload.errors]
    };
  case ACTIONS.REMOVE_LEVER_VALIDATION_ERRORS: {
    const errorList = [...new Set(state.leversErrors.filter((error) => error.leverItem !== action.payload.leverItem))];

    return {
      ...state,
      leversErrors: errorList
    };
  }
  case ACTIONS.RESET_ALL_VALIDATION_ERRORS:
    return {
      ...state,
      leversErrors: []
    };
  default:
    return state;
  }
};

export default leversReducer;
