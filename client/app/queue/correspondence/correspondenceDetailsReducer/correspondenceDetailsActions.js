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
        type: ACTIONS.REMOVE_TASK_NOT_RELATED_TO_APPEAL,
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
export const changeTaskTypeNotRelatedToAppeal = (taskID, payload, taskNames) => (dispatch) => {

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
    }).
    catch((error) => {
      // dispatch({
      //   type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
      //   payload: {
      //     bannerAlert: CORRESPONDENCE_DETAILS_BANNERS.failBanner
      //   }
      // });
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

export const removeTaskNotRelatedToAppealFromStore = (unrelatedTasks) => (dispatch) => {
  dispatch({
    type: ACTIONS.REMOVE_TASK_NOT_RELATED_TO_APPEAL,
    payload: {
      unrelatedTasks
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
