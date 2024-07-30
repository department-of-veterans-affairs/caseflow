import { ACTIONS } from '../constants';
import { update } from '../../util/ReducerUtil';

export const dailyDocketReducer = function(state = {}, action = {}) {
  switch (action.type) {
  case ACTIONS.RECEIVE_DAILY_DOCKET:
    return update(state, {
      hearingDay: { $set: action.payload.hearingDay },
      hearings: { $set: action.payload.hearings }
    });
  case ACTIONS.DISPLAY_LOCK_MODAL:
    return update(state, {
      displayLockModal: {
        $set: true
      }
    });
  case ACTIONS.CANCEL_DISPLAY_LOCK_MODAL:
    return update(state, {
      $unset: ['displayLockModal']
    });
  case ACTIONS.UPDATE_LOCK:
    return update(state, {
      hearingDay: {
        lock: {
          $set: action.payload.lock
        }
      },
      displayLockSuccessMessage: {
        $set: true
      },
      $unset: ['displayLockModal']
    });
  case ACTIONS.RESET_LOCK_SUCCESS_MESSAGE:
    return update(state, {
      $unset: ['displayLockSuccessMessage']
    });

  case ACTIONS.HANDLE_LOCK_HEARING_SERVER_ERROR:
    return update(state, {
      onErrorHearingDayLock: { $set: true },
      displayLockModal: { $set: false }
    });
  case ACTIONS.RESET_LOCK_HEARING_SERVER_ERROR:
    return update(state, {
      $unset: ['onErrorHearingDayLock']
    });
  case ACTIONS.ON_CLICK_REMOVE_HEARING_DAY:
    return update(state, {
      displayRemoveHearingDayModal: {
        $set: true
      }
    });
  case ACTIONS.CANCEL_REMOVE_HEARING_DAY:
    return update(state, {
      $unset: ['displayRemoveHearingDayModal']
    });

  case ACTIONS.HANDLE_DAILY_DOCKET_SERVER_ERROR:
    return update(state, {
      dailyDocketServerError: { $set: true },
      displayRemoveHearingDayModal: { $set: false }
    });
  case ACTIONS.RESET_DAILY_DOCKET_AFTER_SERVER_ERROR:
    return update(state, {
      $unset: ['dailyDocketServerError']
    });
  case ACTIONS.RECEIVE_SAVED_HEARING:
    return update(state, {
      hearings: {
        [action.payload.hearing.externalId]: {
          $set: action.payload.hearing
        }
      },
      saveSuccessful: { $set: action.payload.hearing }
    });
  case ACTIONS.RESET_SAVE_SUCCESSFUL:
    return update(state, {
      $unset: ['saveSuccessful', 'displayLockSuccessMessage']
    });
  case ACTIONS.UPDATE_DOCKET_HEARING:
    return update(state, {
      hearings: {
        [action.payload.hearingId]: {
          $set: {
            ...state.hearings[action.payload.hearingId],
            ...action.payload.values
          }
        }
      }
    });
  case ACTIONS.HEARING_DAY_MODIFIED:
    return update(state, {
      hearingDayModified: {
        $set: action.payload.hearingDayModified
      }
    });
  case ACTIONS.SELECT_VLJ:
    return update(state, {
      vlj: {
        $set: action.payload.vlj
      }
    });
  case ACTIONS.SELECT_COORDINATOR:
    return update(state, {
      coordinator: {
        $set: action.payload.coordinator
      }
    });
  case ACTIONS.SELECT_HEARING_ROOM:
    return update(state, {
      hearingRoom: {
        $set: action.payload.hearingRoom
      }
    });
  case ACTIONS.SET_NOTES:
    return update(state, {
      notes: {
        $set: action.payload.notes
      }
    });
  case ACTIONS.HANDLE_CONFERENCE_LINK_ERROR:
    return update(state, {
      conferenceLinkError: { $set: true }
    });
  default:
    return state;
  }
};

export default dailyDocketReducer;
