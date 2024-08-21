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

export const completeTaskNotRelatedToAppeal = (taskID, payload) => (dispatch) => {

  return ApiUtil.patch(`/queue/correspondence/tasks/${taskID}/complete`, payload).
    then(() => {

      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          // this does not work, unable to pass details to banner: FIXME
          // bannerAlert: CORRESPONDENCE_DETAILS_BANNERS.completeBanner(task, team)
          bannerAlert: CORRESPONDENCE_DETAILS_BANNERS.completeBanner
        }
      });

    }).
    catch((error) => {
      dispatch({
        type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
        payload: {
          // this does not work, unable to pass details to banner: FIXME
          // bannerAlert: CORRESPONDENCE_DETAILS_BANNERS.completeFailBanner(task, team)
          bannerAlert: CORRESPONDENCE_DETAILS_BANNERS.completeFailBanner
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

export const setShowActionsDropdown = (showActionsDropdown) => (dispatch) => {
  dispatch({
    type: ACTIONS.SHOW_ACTIONS_DROP_DOWN,
    payload: {
      showActionsDropdown
    }
  });

};
