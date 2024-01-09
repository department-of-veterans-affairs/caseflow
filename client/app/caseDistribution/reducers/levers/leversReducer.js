import {ACTIONS } from '../levers/leversActionTypes';
import { update } from '../../../util/ReducerUtil';
import { Constant } from '../../constants'

// saveChangesActivated, editedLevers, formattedHistory, changesOccurred should be deleted. Refactor where it is used before deletion
export const initialState = {
  saveChangesActivated: false,
  editedLevers: [],
  levers: {},
  backendLevers: [],
  formattedHistory: {},
  historyList: [],
  changesOccurred: false,
  showSuccessBanner: false,
  isUserAcdAdmin: false
};

const leversReducer = (state = initialState, action = {}) => {
  switch (action.type) {

    case ACTIONS.INITIAL_LOAD:
      // all of the logic to append currentValue and backendValue needs to be moved to LOAD_LEVERS
      // remove all calls to INITIAL_LOAD and use LOAD_LEVERS instead
      const leverGroups = Object.keys(action.payload.levers);

      const leversWithValues = () => {
        return leverGroups.reduce((updatedLevers, leverGroup) => {
          updatedLevers[leverGroup] = action.payload.levers[leverGroup].map(lever => {
            let value = null;
            const group = lever.lever_group
            if (group === Constant.AFFINITY) {
              value = lever.options.find(option => option.item === lever.value).value;
            } else if (group === Constant.DOCKET_DISTRIBUTION_PRIOR) {
              value = `${lever.is_toggle_active}-${lever.value}`;
             }
            else {
              value = lever.value;
            }

            // Add backendValue and currentValue attributes
            return {
              ...lever,
              backendValue: value,
              currentValue: value,
            };
          });

          return updatedLevers;
        }, {});
      };

      const updatedLeversWithValues = leversWithValues();

      return update(state, {
        levers: {
          $set: updatedLeversWithValues,
        },
        backendLevers: {
          $set: updatedLeversWithValues,
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
    //   lever.currentValue = value;
    // }))
    return update(state, {
      levers: {
        $set: action.payload.levers
      }
    });

    case ACTIONS.SET_USER_IS_ACD_ADMIN:

    return update(state, {
      isUserAcdAdmin: {
        $set: action.payload.isUserAcdAdmin
      }
    })

    case ACTIONS.UPDATE_LEVER:
      const { leverGroup, leverItem, value, optionValue, toggleValue } = action.payload;
      const updateLeverValue = (lever) => {
        if (leverGroup === Constant.AFFINITY) {
          const selectedOption = lever.options.find(option => option.item ===value)
          selectedOption.value = optionValue
          return { ...lever, currentValue: optionValue, value };
        } else if (leverGroup === Constant.DOCKET_DISTRIBUTION_PRIOR) {
          return { ...lever, value, currentValue: `${toggleValue}-${value}`, is_toggle_active: toggleValue };
        } else {
          return { ...lever, value, currentValue: value };
        }
      };
      const updatedLever = state.levers[leverGroup].map((lever) =>
        lever.item === leverItem ? updateLeverValue(lever) : lever
      );
      return {
        ...state,
        levers: {
          ...state.levers,
          [leverGroup]: updatedLever,
        },
      };
  // needs to be reworked; remove comment when done
  case ACTIONS.FORMAT_LEVER_HISTORY:
    return {
      ...state,
      historyList: formatLeverHistory(action.history)
    };

  // needs to be reworked; remove comment when done
  // we are no longer going to be replacing the backendLevers with levers on save. We will be replacing the list upon save with data from the backend
  case ACTIONS.SAVE_LEVERS:
    return {
      ...state,
      backendLevers: state.levers,
      saveChangesActivated: action.saveChangesActivated,
      changesOccurred: false
    };

  // needs to be reworked; remove comment when done
  case ACTIONS.REVERT_LEVERS:
    return {
      ...state,
      levers: state.backendLevers
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

// this should probably be moved into the action in leversAction.js
export const formatLeverHistory = (lever_history_list) => {
  let formatted_lever_history = [];

  lever_history_list.forEach((lever_history_entry) => {

    formatted_lever_history.push(
      {
        user_name: lever_history_entry.user,
        created_at: lever_history_entry.created_at,
        lever_title: lever_history_entry.title,
        original_value: lever_history_entry.original_value,
        current_value: lever_history_entry.current_value
      }
    );
  });

  return formatted_lever_history;
};

// this should probably be moved into the action in leversAction.js
export const updateLevers = (current_levers, updated_lever, hasValueChanged) => {
  const leverIndex = current_levers.findIndex((lever) => lever.item == updated_lever.item);

  if (leverIndex !== -1) {

    const updatedLevers = [...current_levers];

    updatedLevers[leverIndex] = {
      ...updatedLevers[leverIndex],
      value: updated_lever.value,
      hasValueChanged
    };

    return updatedLevers;
  }

  return current_levers;
};

export default leversReducer;
