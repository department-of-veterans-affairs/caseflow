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

export const cancelTaskNotRelatedToAppeal = (taskID, correspondence, payload) => (dispatch) => {

  return ApiUtil.patch(`/queue/correspondence/tasks/${taskID}/cancel`, payload).
    then(() => {

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: CORRESPONDENCE_DETAILS_BANNERS.successBanner
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
      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: CORRESPONDENCE_DETAILS_BANNERS.failBanner
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
      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: CORRESPONDENCE_DETAILS_BANNERS.completeFailBanner
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
      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: {
            title: CORRESPONDENCE_DETAILS_BANNERS.teamFailBanner,
            message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.teamFailBanner,
              error.response.body.message),
            type: CORRESPONDENCE_DETAILS_BANNERS.teamFailBanner
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
    } });
};

export const setTasksUnrelatedToAppealEmpty = (tasksUnrelatedToAppealEmpty) => (dispatch) => {
  dispatch({
    type: ACTIONS.TASKS_UNRELATED_TO_APPEAL_EMPTY,
    payload: {
      tasksUnrelatedToAppealEmpty
    }
  });
};
