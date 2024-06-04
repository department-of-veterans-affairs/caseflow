import { ACTIONS } from './leversActionTypes';
import ApiUtil from '../../../util/ApiUtil';
import { validateLeverInput } from '../../utils';

export const loadAcdExcludeFromAffinity = (acdExcludeFromAffinity) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_ACD_EXCLUDE_FROM_AFFINITY,
      payload: {
        acdExcludeFromAffinity
      }
    });
  };

export const setUserIsAcdAdmin = (isUserAcdAdmin) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_USER_IS_ACD_ADMIN,
      payload: {
        isUserAcdAdmin
      }
    });
  };

export const loadLevers = (levers) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.LOAD_LEVERS,
      payload: {
        levers
      }
    });
  };

export const loadHistory = (historyList) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.LOAD_HISTORY,
      payload: {
        historyList
      }
    });
  };

export const resetLevers = () => async (dispatch) => {
  const resp = await ApiUtil.get('/case_distribution_levers/levers');
  const { levers } = resp.body;

  dispatch({
    type: ACTIONS.LOAD_LEVERS,
    payload: {
      levers,
    },
  });
};

/**
 * Used when updating a radio lever
 * Pass in the selected option and a value if the selected option is value
 *
 * This will break if a Radio lever has more than one option that has an input
 *
 * @param {*} leverGroup is the group the lever is in:
 *      affinity, batch, docket_distribution_prior, docket_time_goal, docket_levers
 * @param {*} leverItem is the name of the lever:
 *      see DISTRIBUTION.json for valid names
 * @param {*} optionItem is the option that was selected:
 *      value, omit, infinite
 * @param {*} optionValue if value option is the selected the value of the input
 * @returns
 */
export const updateRadioLever = (leverGroup, leverItem, optionItem, optionValue = null) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_RADIO_LEVER,
      payload: {
        leverGroup,
        leverItem,
        optionItem,
        optionValue
      }
    });
  };

export const updateLeverIsToggleActive = (leverGroup, leverItem, toggleValue) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_LEVER_IS_TOGGLE_ACTIVE,
      payload: {
        leverGroup,
        leverItem,
        toggleValue
      }
    });
  };

export const updateLeverValue = (leverGroup, leverItem, value) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_LEVER_VALUE,
      payload: {
        leverGroup,
        leverItem,
        value
      }
    });
  };

export const saveLevers = (levers) =>
  (dispatch) => {
    const changedValues = levers.
      map((lever) => ({
        id: lever.id,
        value: lever.value,
        is_toggle_active: lever.is_toggle_active
      }));

    const postData = {
      current_levers: changedValues
    };

    return ApiUtil.post('/case_distribution_levers/update_levers', { data: postData }).
      then((resp) => {
        const response = (resp.body);

        if (resp.body.status_code === 500) {
          dispatch({
            type: ACTIONS.SET_USER_IS_ACD_ADMIN,
            payload: {
              isUserAcdAdmin: response.user_is_an_acd_admin
            }
          });
          throw new Error(response.message);
        } else {
          dispatch({
            type: ACTIONS.LOAD_LEVERS,
            payload: {
              levers: response.levers,
            }
          });
          dispatch({
            type: ACTIONS.SAVE_LEVERS,
            payload: {
              errors: response.errors,
            }
          });
          dispatch({
            type: ACTIONS.LOAD_HISTORY,
            payload: {
              historyList: response.lever_history
            }
          });
        }
      }).
      catch((error) => {
        dispatch({
          type: ACTIONS.SAVE_LEVERS,
          payload: {
            errors: [error.message],
          }
        });
      });
  };

export const hideSuccessBanner = () =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.HIDE_BANNER
    });
  };

export const addLeverErrors = (errors) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.ADD_LEVER_VALIDATION_ERRORS,
      payload: {
        errors
      }
    });
  };

export const removeLeverErrors = (leverItem) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.REMOVE_LEVER_VALIDATION_ERRORS,
      payload: {
        leverItem
      }
    });
  };

export const resetAllLeverErrors = () =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.RESET_ALL_VALIDATION_ERRORS
    });
  };

export const validateLever = (lever, leverItem, value, leverErrors) => (dispatch) => {
  const validationErrors = validateLeverInput(lever, value);
  const errorExists = leverErrors.length > 0;

  if (validationErrors.length > 0 && !errorExists) {
    dispatch(addLeverErrors(validationErrors));
  }

  if (validationErrors.length === 0 && errorExists) {
    dispatch(removeLeverErrors(leverItem));
  }

};
