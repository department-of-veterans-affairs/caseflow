import { ACTIONS } from './correspondenceConstants';
import ApiUtil from '../../../util/ApiUtil';

export const loadSavedIntake = (savedStore) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.LOAD_SAVED_INTAKE,
      payload: {
        savedStore
      }
    });
  };

export const saveCurrentIntake = (currentIntake, data, onSave) => (dispatch) => {
  ApiUtil.post(`/queue/correspondence/${data.correspondence_uuid}/current_step`, { data }).
    then((response) => {
      if (!response.ok) {
        console.error(response);
      }

      dispatch({
        type: ACTIONS.SAVE_CURRENT_INTAKE,
        payload: {
          currentIntake
        }
      });
      if (onSave) {
        onSave();
      }
    }).
    catch((err) => {
      console.error(new Error(`Problem with GET ${currentIntake} ${err}`));
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

export const loadCorrespondence = (correspondence) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.LOAD_CORRESPONDENCE,
      payload: {
        correspondence
      }
    });
  };

export const loadCorrespondenceConfig = (configUrl) =>
  (dispatch) => {
    ApiUtil.get(configUrl).then(
      (response) => {
        const returnedObject = response.body;
        const correspondenceConfig = returnedObject.correspondence_config;

        dispatch(
          {
            type: ACTIONS.LOAD_CORRESPONDENCE_CONFIG,
            payload: {
              correspondenceConfig
            }
          });

      }).
      catch(
        (err) => {
          console.error(new Error(`Problem with GET ${configUrl} ${err}`));
        });
  };

export const updateRadioValue = (value) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_RADIO_VALUE,
      payload: value
    });
  };

export const saveCheckboxState = (correspondence, isChecked) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SAVE_CHECKBOX_STATE,
      payload: {
        correspondence, isChecked
      }
    });
  };

export const clearCheckboxState = () =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.CLEAR_CHECKBOX_STATE,
    });
  };

export const setSelectedTasks = (values) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_SELECTED_TASKS,
      payload: { values }
    });
  };

export const setTaskRelatedAppealIds = (appealIds) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_TASK_RELATED_APPEAL_IDS,
      payload: {
        appealIds
      }
    });
  };

export const setUnrelatedTasks = (tasks) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_UNRELATED_TASKS,
      payload: {
        tasks
      }
    });
  };

export const setFetchedAppeals = (appeals) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_FETCHED_APPEALS,
      payload: {
        appeals
      }
    });
  };

export const saveMailTaskState = (name) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SAVE_MAIL_TASK_STATE,
      payload: {
        name
      }
    });
  };

export const setNewAppealRelatedTasks = (newAppealRelatedTasks) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_NEW_APPEAL_RELATED_TASKS,
      payload: {
        newAppealRelatedTasks
      }
    });
  };

export const setWaivedEvidenceTasks = (task) => (dispatch) => {
  dispatch({
    type: ACTIONS.SET_WAIVED_EVIDENCE_TASKS,
    payload: {
      task
    }
  });
};

export const setResponseLetters = (responseLetters) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_RESPONSE_LETTERS,
      payload: {
        responseLetters
      }
    });
  };

export const removeResponseLetters = (index) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.REMOVE_RESPONSE_LETTERS,
      payload: {
        index
      }
    });
  };

export const setShowReassignPackageModal = (isVisible) => (dispatch) => {
  dispatch({
    type: ACTIONS.SET_SHOW_REASSIGN_PACKAGE_MODAL,
    payload: {
      isVisible
    }
  });
};

export const setShowRemovePackageModal = (isVisible) => (dispatch) => {
  dispatch({
    type: ACTIONS.SET_SHOW_REMOVE_PACKAGE_MODAL,
    payload: {
      isVisible
    }
  });
};

export const setSelectedVeteranDetails = (selectedVeteranDetails) => (dispatch) => {
  dispatch({
    type: ACTIONS.SET_SELECTED_VETERAN_DETAILS,
    payload: {
      selectedVeteranDetails
    }
  });
};

export const setErrorBanner = (isVisible) => (dispatch) => {
  dispatch({
    type: ACTIONS.SET_SHOW_CORRESPONDENCE_INTAKE_FORM_ERROR_BANNER,
    payload: {
      isVisible
    }
  });
};
