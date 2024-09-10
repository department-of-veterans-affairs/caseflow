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
      const errorMessage = error?.response?.body?.message
        ? error.response.body.message.replace(/^Error:\s*/, '')
        : error.message;

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
      const errorMessage = error?.response?.body?.message
        ? error.response.body.message.replace(/^Error:\s*/, '')
        : error.message;

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
      const errorMessage = error?.response?.body?.message
        ? error.response.body.message.replace(/^Error:\s*/, '')
        : error.message;

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
      const errorMessage = error?.response?.body?.message
        ? error.response.body.message.replace(/^Error:\s*/, '')
        : error.message;

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
      const errorMessage = error?.response?.body?.message
        ? error.response.body.message.replace(/^Error:\s*/, '')
        : error.message;

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

export const correspondenceInfo = (correspondence) => (dispatch) => {
  dispatch({
    type: ACTIONS.CORRESPONDENCE_INFO,
    payload: {
      correspondence
    }
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
