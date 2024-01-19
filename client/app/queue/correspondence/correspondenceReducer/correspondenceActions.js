import { ACTIONS } from './correspondenceConstants';

export const loadCurrentCorrespondence = (currentCorrespondence) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.LOAD_CURRENT_CORRESPONDENCE,
      payload: {
        currentCorrespondence
      }
    });
  };

export const loadCorrespondences = (correspondences) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.LOAD_CORRESPONDENCES,
      payload: {
        correspondences
      }
    });
  };

export const loadVeteranInformation = (veteranInformation) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.LOAD_VETERAN_INFORMATION,
      payload: {
        veteranInformation
      }
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

export const loadCorrespondenceTasks = (correspondenceTasks) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.LOAD_CORRESPONDENCE_TASKS,
      payload: {
        correspondenceTasks
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
