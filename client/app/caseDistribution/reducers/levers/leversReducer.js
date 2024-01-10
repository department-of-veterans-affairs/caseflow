import { ACTIONS } from '../levers/leversActionTypes';
import { update } from '../../../util/ReducerUtil';
import {
  createUpdatedLever,
  createUpdatedRadioLever,
  createUpdatedCombinationLever,
  createUpdatedLeversWithValues,
  formatLeverHistory
} from '../../utils';

// saveChangesActivated, editedLevers, formattedHistory, changesOccurred should be deleted.
// Refactor where it is used before deletion
export const initialState = {
  saveChangesActivated: false,
  editedLevers: [],
  levers: {},
  backendLevers: [],
  formattedHistory: {},
  historyList: [],
  changesOccurred: false,
  showSuccessBanner: false,
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
    // const leverGroups = Object.keys(action.payload.levers)
    // const levers = leverGroups.forEach(leverGroup => leverGroup.forEach(lever => {
    //   let value = null;
    //    switch(lever.lever_group) {
    //     case Constant.AFFINITY:
    //       value = lever.options[lever.value].value
    //       return
    //     default:
    //       value = lever.value
    //       return
    //   }
    //   lever.backendValue = value;
    //   lever.value = value;
    // }))
    return update(state, {
      levers: {
        $set: action.payload.levers
      }
    });

  case ACTIONS.UPDATE_BOOLEAN_LEVER:
  case ACTIONS.UPDATE_NUMBER_LEVER:
  case ACTIONS.UPDATE_TEXT_LEVER: {
    const [leverGroup, hasValueChanged] = createUpdatedLever(state, action);

    return {
      ...state,
      changesOccurred: hasValueChanged,
      levers: {
        ...state.levers,
        [action.payload.leverGroup]: leverGroup,
      },
    };
  }
  case ACTIONS.UPDATE_COMBINATION_LEVER: {
    const [leverGroup, hasValueChanged] = createUpdatedCombinationLever(state, action);

    return {
      ...state,
      changesOccurred: hasValueChanged,
      levers: {
        ...state.levers,
        [action.payload.leverGroup]: leverGroup,
      },
    };
  }
  case ACTIONS.UPDATE_RADIO_LEVER: {
    const [leverGroup, hasValueChanged] = createUpdatedRadioLever(state, action);

    return {
      ...state,
      changesOccurred: hasValueChanged,
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
      backendLevers: state.levers,
      saveChangesActivated: action.saveChangesActivated,
      changesOccurred: false
    };

  case ACTIONS.REVERT_LEVERS:
    return {
      ...state,
      levers: createUpdatedLeversWithValues(state.backendLevers)
    };

  // needs to be reworked; remove comment when done
  case ACTIONS.SHOW_SUCCESS_BANNER:
    return {
      ...state,
      showSuccessBanner: true
    };

  // needs to be reworked; remove comment when done
  case ACTIONS.HIDE_SUCCESS_BANNER:
    return {
      ...state,
      showSuccessBanner: false
    };

  default:
    return state;
  }
};

export default leversReducer;
