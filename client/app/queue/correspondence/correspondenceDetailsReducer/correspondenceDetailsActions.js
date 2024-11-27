import { ACTIONS } from './correspondenceDetailsConstants';
import ApiUtil from '../../../util/ApiUtil';
import { sprintf } from 'sprintf-js';
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

      correspondence.correspondenceResponseLetters = responseLetters

      dispatch({
        type: ACTIONS.CORRESPONDENCE_INFO,
        payload: correspondence
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

export const returnTaskToInboundOps = (payload, frontendParams, correspondenceInfo) => (dispatch) => {
  const { taskId } = frontendParams;

  return ApiUtil.post(`/queue/correspondence/tasks/${taskId}/return_to_inbound_ops`, payload).
    then((response) => {
      const { title, message, type } = CORRESPONDENCE_DETAILS_BANNERS.returnToInboundOpsBanner;
      const updatedTasks = response.body;

      // Remove the current task that has now been cancelled
      const filteredTasks = correspondenceInfo.tasksUnrelatedToAppeal.filter(
        (task) => parseInt(task.uniqueId, 10) === parseInt(taskId, 10)
      );

      correspondenceInfo.tasksUnrelatedToAppeal = filteredTasks;

      // Add updated cancelled task and created return task
      correspondenceInfo.tasksUnrelatedToAppeal.push(updatedTasks.return_task);
      correspondenceInfo.closedTasksUnrelatedToAppeal.push(updatedTasks.closed_task);
      console.log(correspondenceInfo);

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title,
            message,
            type
          }
        }
      });

      dispatch({
        type: ACTIONS.CORRESPONDENCE_INFO,
        payload: {
          correspondenceInfo
        }
      });
    }).
    catch((error) => {
      const errorMessage = error?.response?.body?.message ?
        error.response.body.message.replace(/^Error:\s*/, '') :
        error.message;

      const { title, message, type } = CORRESPONDENCE_DETAILS_BANNERS.taskActionFailBanner;

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title,
            message: sprintf(message, errorMessage),
            type
          }
        }
      });

      console.error(error);
    });
};
