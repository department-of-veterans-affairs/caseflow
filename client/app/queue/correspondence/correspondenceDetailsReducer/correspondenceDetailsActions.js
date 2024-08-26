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
export const cancelTaskNotRelatedToAppeal = (taskID, payload) => (dispatch) => {

  return ApiUtil.patch(`/queue/correspondence/tasks/${taskID}/cancel`, payload).
    then(() => {

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          bannerAlert: CORRESPONDENCE_DETAILS_BANNERS.successBanner
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

export const assignTaskToTeam = (taskID, correspondence, payload, organizationLabel) => async (dispatch) => {
  try {
    // Make the API call to assign the task
    await ApiUtil.patch(`/queue/correspondence/tasks/${taskID}/assign_to_team`, payload);

    // Dispatch a success banner alert
    dispatch({
      type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
      payload: {
        bannerAlert: {
          title: 'Success',
          message: `FOIA request task has been assigned to ${organizationLabel}`,
          type: 'success'
        }
      }
    });

    // Update the correspondence info in the state
    dispatch({
      type: ACTIONS.CORRESPONDENCE_INFO,
      payload: {
        correspondence
      }
    });
  } catch (error) {
    // Dispatch a failure banner alert
    dispatch({
      type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
      payload: {
        bannerAlert: {
          title: 'Error',
          message: `Task action could not be completed. Please try again at a
          later time or contact the Help Desk (Error code: ${error.message})`,
          type: 'error'
        }
      }
    });
    // Log the error to the console for debugging
    console.error(error);
  }
};


export const correspondenceInfo = (correspondence) => (dispatch) => {
  dispatch({
    type: ACTIONS.CORRESPONDENCE_INFO,
    payload: {
      correspondence
    } });
};

export const setShowActionsDropdown = (showActionsDropdown) => (dispatch) => {
  dispatch({
    type: ACTIONS.SHOW_ACTIONS_DROP_DOWN,
    payload: {
      showActionsDropdown
    }
  });

};
