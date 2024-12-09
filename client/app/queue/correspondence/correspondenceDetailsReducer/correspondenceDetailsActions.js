/* eslint-disable max-lines */
import { ACTIONS } from './correspondenceDetailsConstants';
import ApiUtil from '../../../util/ApiUtil';
import { sprintf } from 'sprintf-js';
import { prepareTasksForStore } from '../../utils';
import { onReceiveTasks, deleteAmaTask } from '../../QueueActions';
// eslint-disable-next-line import/extensions
import CORRESPONDENCE_DETAILS_BANNERS from '../../../../constants/CORRESPONDENCE_DETAILS_BANNERS.json';

export const setTaskNotRelatedToAppealBanner = (bannerDetails) => (dispatch) => {
  dispatch({
    type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
    payload: {
      bannerAlert: {
        title: bannerDetails.title,
        message: bannerDetails.message,
        type: bannerDetails.type
      }
    }
  });
};

export const fetchCorrespondencesAppealsTasks = (uuid) => (dispatch) => {
  return ApiUtil.get(`/queue/correspondence/${uuid}/correspondences_appeals_tasks`).
    then((response) => {
      JSON.stringify(`response ${response, 1, 1}`)
      const responseTasks = JSON.parse(response.text).tasks.data;

      // overwrite all correspondence_appeal_tasks in the store with values from response
      const preparedTasks = prepareTasksForStore(responseTasks);

      dispatch(onReceiveTasks({
        amaTasks: preparedTasks
      }));
    }).
    catch((error) => {
      const errorMessage = error?.response?.body?.message ?
        error.response.body.message.replace(/^Error:\s*/, '') :
        error.message;

      console.error(errorMessage);
    });
};

export const createNewEvidenceWindowTask = (payload, correspondence, appealId) => (dispatch) => {
  return ApiUtil.post(`/queue/correspondence/${correspondence.uuid}/waive_evidence_submission_window_task`, payload).
    then((response) => {
      const responseData = JSON.parse(response.text);
      const responseTasks = responseData.tasks.data;

      // remove old task from store
      dispatch(deleteAmaTask(
        payload.data.task.task_id
      ));

      // Dispatch the banner alert to the store
      dispatch({
        type: ACTIONS.EVIDENCE_SUBMISSION_BANNER,
        payload: {
          waiveEvidenceAlertBanner: {
            appealId,
            title: CORRESPONDENCE_DETAILS_BANNERS.evidenceWindowBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.evidenceWindowBanner.message),
            type: CORRESPONDENCE_DETAILS_BANNERS.evidenceWindowBanner.type
          }
        }
      });

      // overwrite all correspondence_appeal_tasks in the store with values from response
      const preparedTasks = prepareTasksForStore(responseTasks);

      dispatch(onReceiveTasks({
        amaTasks: preparedTasks
      }));
    }).

    catch((error) => {
      const errorMessage = error?.response?.body?.message ?
        error.response.body.message.replace(/^Error:\s*/, '') :
        error.message;

      console.error(errorMessage);
    });
};

export const cancelTaskNotRelatedToAppeal = (taskID, taskName, teamName, correspondence, payload) => (dispatch) => {

  return ApiUtil.patch(`/queue/correspondence/tasks/${taskID}/cancel`, payload).
    then(() => {

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title: CORRESPONDENCE_DETAILS_BANNERS.cancelSuccessBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.cancelSuccessBanner.message,
              taskName, teamName),
            type: CORRESPONDENCE_DETAILS_BANNERS.cancelSuccessBanner.type
          }
        }
      });

      dispatch({
        type: ACTIONS.CORRESPONDENCE_INFO,
        payload: {
          correspondence
        }
      });

    }).
    catch((error) => {
      const errorMessage = error?.response?.body?.message ?
        error.response.body.message.replace(/^Error:\s*/, '') :
        error.message;

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.message,
              errorMessage),
            type: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.type
          }
        }
      });
      console.error(error);
    });
};

export const changeTaskTypeNotRelatedToAppeal = (taskID, payload, taskNames, correspondence) => (dispatch) => {

  return ApiUtil.patch(`/queue/correspondence/tasks/${taskID}/change_task_type`, payload).
    then(() => {

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title: 'Success',
            // eslint-disable-next-line max-len
            message: `You have changed the task type from ${taskNames.oldType} to ${taskNames.newType}. These changes are now reflected in the tasks section below.`,
            type: 'success'
          }
        }
      });

      dispatch({
        type: ACTIONS.CORRESPONDENCE_INFO,
        payload: {
          correspondence
        }
      });
    }).
    catch((error) => {
      const errorMessage = error?.response?.body?.message ?
        error.response.body.message.replace(/^Error:\s*/, '') :
        error.message;

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.message,
              errorMessage),
            type: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.type
          }
        }
      });
      console.error(error);
    });
};

export const completeTaskNotRelatedToAppeal = (payload, frontendParams, correspondence) => (dispatch) => {

  return ApiUtil.patch(`/queue/correspondence/tasks/${frontendParams.taskId}/complete`, payload).
    then(() => {

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title: CORRESPONDENCE_DETAILS_BANNERS.completeBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.completeBanner.message,
              frontendParams.taskName,
              frontendParams.teamName),
            type: CORRESPONDENCE_DETAILS_BANNERS.completeBanner.type
          }
        }
      });

      dispatch({
        type: ACTIONS.CORRESPONDENCE_INFO,
        payload: {
          correspondence
        }
      });

    }).
    catch((error) => {
      const errorMessage = error?.response?.body?.message ?
        error.response.body.message.replace(/^Error:\s*/, '') :
        error.message;

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.message,
              errorMessage),
            type: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.type
          }
        }
      });
      console.error(error);
    });
};

export const assignTaskToUser = (taskID, payload, frontendParams, correspondence) => (dispatch) => {

  return ApiUtil.patch(`/queue/correspondence/tasks/${taskID}/assign_to_person`, payload).
    then(() => {

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title: CORRESPONDENCE_DETAILS_BANNERS.assignSuccessBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.assignSuccessBanner.message,
              frontendParams.taskName,
              frontendParams.assignedName),
            type: CORRESPONDENCE_DETAILS_BANNERS.assignSuccessBanner.type
          }
        }
      });

      dispatch({
        type: ACTIONS.CORRESPONDENCE_INFO,
        payload: {
          correspondence
        }
      });

    }).
    catch((error) => {
      const errorMessage = error?.response?.body?.message ?
        error.response.body.message.replace(/^Error:\s*/, '') :
        error.message;

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.message,
              errorMessage),
            type: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.type
          }
        }
      });
      console.error(error);
    });
};

export const assignTaskToTeam = (payload, frontendParams, correspondence) => (dispatch) => {
  return ApiUtil.patch(`/queue/correspondence/tasks/${frontendParams.taskId}/assign_to_team`, payload).
    then(() => {

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title: CORRESPONDENCE_DETAILS_BANNERS.teamBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.teamBanner.message,
              frontendParams.taskName,
              frontendParams.teamName),
            type: CORRESPONDENCE_DETAILS_BANNERS.teamBanner.type
          }
        }
      });

      dispatch({
        type: ACTIONS.CORRESPONDENCE_INFO,
        payload: {
          correspondence
        }
      });

    }).
    catch((error) => {
      const errorMessage = error?.response?.body?.message ?
        error.response.body.message.replace(/^Error:\s*/, '') :
        error.message;

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.message,
              errorMessage),
            type: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.type
          }
        }
      });
      console.error(error);
    });
};

export const submitLetterResponse = (payload, correspondence) => (dispatch) => {
  const uuid = correspondence.uuid;
  const url = `/queue/correspondence/${uuid}/correspondence_response_letter`;

  return ApiUtil.post(url, payload).
    then((response) => {
      const responseLetters = response.body.responseLetters;

      correspondence.correspondenceResponseLetters = responseLetters;

      dispatch({
        type: ACTIONS.CORRESPONDENCE_INFO,
        payload: {
          correspondence
        }
      });
    });
};

export const setTasksUnrelatedToAppealEmpty = (tasksUnrelatedToAppealEmpty) => (dispatch) => {
  dispatch({
    type: ACTIONS.TASKS_UNRELATED_TO_APPEAL_EMPTY,
    payload: {
      tasksUnrelatedToAppealEmpty
    }
  });
};

// Add task not related to appeal
export const addTaskNotRelatedToAppeal = (correspondence, taskData) => (dispatch) => {
  const patchData = {
    tasks_not_related_to_appeal: [{
      klass: taskData.klass,
      assigned_to: taskData.assigned_to,
      content: taskData.content,
      label: taskData.label,
      assignedOn: taskData.assignedOn,
      instructions: taskData.instructions
    }]
  };

  // Return a promise so that the caller can await the result
  return ApiUtil.patch(`/queue/correspondence/${correspondence.uuid}/update_correspondence`, { data: patchData }).
    then((response) => {
      // Fetch the updated correspondence information from the response
      const updatedCorrespondence = response.body.correspondence;

      // Dispatch action to update correspondence info in the Redux store
      dispatch({
        type: ACTIONS.CORRESPONDENCE_INFO,
        payload: {
          correspondence: updatedCorrespondence
        }
      });

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title: CORRESPONDENCE_DETAILS_BANNERS.completeTaskCreationBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.completeTaskCreationBanner.message, taskData.label),
            type: CORRESPONDENCE_DETAILS_BANNERS.completeTaskCreationBanner.type
          }
        }
      });

      // Return the response for any further handling
      return response;
    }).
    catch((error) => {
      const errorMessage = error?.response?.body?.message ?
        error.response.body.message.replace(/^Error:\s*/, '') :
        error.message;

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.message, errorMessage),
            type: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.type
          }
        }
      });

      // Reject the promise to handle the error in the component
      return Promise.reject(error);
    });
};

export const createCorrespondenceAppealTask = (data, correspondence, appealId) => async (dispatch) => {

  return ApiUtil.patch(`/queue/correspondence/${correspondence.uuid}/create_correspondence_appeal_task`,
    { data }).
    then((response) => {

      // Dispatch action to update tasks
      const responseTasks = JSON.parse(response.text).tasks.data;

      const preparedTasks = prepareTasksForStore(responseTasks);

      dispatch(onReceiveTasks({
        amaTasks: preparedTasks
      }));

      dispatch({
        type: ACTIONS.SET_TASK_RELATED_TO_APPEAL_BANNER,
        payload: {
          taskRelatedToAppealBanner: {
            appealId,
            title: CORRESPONDENCE_DETAILS_BANNERS.completeTaskCreationBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.completeTaskCreationBanner.message, data.label),
            type: CORRESPONDENCE_DETAILS_BANNERS.completeTaskCreationBanner.type
          }
        }
      });

      return response;
    }).
    catch((error) => {
      const errorMessage = error?.response?.body?.message ?
        error.response.body.message.replace(/^Error:\s*/, '') :
        error.message;

      dispatch({
        type: ACTIONS.SET_TASK_RELATED_TO_APPEAL_BANNER,
        payload: {
          taskRelatedToAppealBanner: {
            appealId,
            title: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.title,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.message, errorMessage),
            type: CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner.type
          }
        }
      });

      return Promise.reject(error);
    });
};

export const updateCorrespondenceInfo = (correspondence) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.CORRESPONDENCE_INFO,
      payload: {
        correspondence
      }
    });
  };

export const editCorrespondenceGeneralInformation = (payload, uuid) => (dispatch) => {
  return ApiUtil.patch(`/queue/correspondence/${uuid}/edit_general_information`, payload).
    then((response) => {
      const correspondence = response.body.correspondence;

      dispatch({
        type: ACTIONS.CORRESPONDENCE_INFO,
        payload: {
          correspondence
        }
      });

    }).
    catch((error) => {
      const errorMessage = error?.response?.body?.message ?
        error.response.body.message.replace(/^Error:\s*/, '') :
        error.message;

      console.error(errorMessage);
    });
};

export const updateExpandedLinkedAppeals = (expandedLinkedAppeals, uuid) => (dispatch) => {
  if (expandedLinkedAppeals.find((id) => id === uuid)) {
    const filteredList = expandedLinkedAppeals.filter((id) => id !== uuid);

    dispatch({
      type: ACTIONS.EXPANDED_LINKED_APPEALS,
      payload: {
        expandedLinkedAppeals: filteredList
      }
    });

  } else {
    expandedLinkedAppeals.push(uuid);

    dispatch({
      type: ACTIONS.EXPANDED_LINKED_APPEALS,
      payload: {
        expandedLinkedAppeals
      }
    });
  }
};

export const updateVeteranInformation = (payload) => (dispatch) => {
  dispatch({
    type: ACTIONS.VETERAN_INFORMATION,
    payload: {
      veteranInformation: payload
    }
  });
};
