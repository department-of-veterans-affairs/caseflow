import { ACTIONS } from './correspondenceDetailsConstants';
import ApiUtil from '../../../util/ApiUtil';
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

      // dispatch({
      //   type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
      //   payload: {
      //     bannerAlert: {
      //       title: "Test Title",
      //       message: "Test Message"
      //     }
      //     // bannerAlert: {
      //     //   title: CORRESPONDENCE_DETAILS_BANNERS.assignSuccessBanner.title,
      //     //   message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.assignSuccessBanner.message,
      //     //     correspondence.label,
      //     //     payload.assigned_to),
      //     //   type: CORRESPONDENCE_DETAILS_BANNERS.assignSuccessBanner.type
      //     // }
      //   }
      // });

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

// export const completeTaskNotRelatedToAppeal = (payload, frontendParams, correspondence) => (dispatch) => {

//   return ApiUtil.patch(`/queue/correspondence/tasks/${frontendParams.taskId}/complete`, payload).
//     then(() => {

//       dispatch({
//         type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
//         payload: {
//           bannerAlert: {
//             title: CORRESPONDENCE_DETAILS_BANNERS.completeBanner.title,
//             message: sprintf(CORRESPONDENCE_DETAILS_BANNERS.completeBanner.message,
//               frontendParams.taskName,
//               frontendParams.teamName),
//             type: CORRESPONDENCE_DETAILS_BANNERS.completeBanner.type
//           }
//         }
//       });

//       dispatch({
//         type: ACTIONS.CORRESPONDENCE_INFO,
//         payload: {
//           correspondence
//         }
//       });

//     }).
//     catch((error) => {
//       dispatch({
//         type: ACTIONS.SET_CORRESPONDENCE_TASK_NOT_RELATED_TO_APPEAL_BANNER,
//         payload: {
//           bannerAlert: CORRESPONDENCE_DETAILS_BANNERS.completeFailBanner
//         }
//       });
//       console.error(error);
//     });
// };

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
