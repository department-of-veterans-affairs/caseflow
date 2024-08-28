import { ACTIONS } from './correspondenceDetailsConstants';
import ApiUtil from '../../../util/ApiUtil';
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
      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: CORRESPONDENCE_DETAILS_BANNERS.assignFailBanner
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

export const setShowActionsDropdown = (showActionsDropdown) => (dispatch) => {
  dispatch({
    type: ACTIONS.SHOW_ACTIONS_DROP_DOWN,
    payload: {
      showActionsDropdown
    }
  });
};
