import { ACTIONS } from '../constants';
import { update } from '../../util/ReducerUtil';

export const dailyDocketReducer = function(state = {}, action = {}) {
  switch (action.type) {
  case ACTIONS.RECEIVE_DAILY_DOCKET:
    return update(state, {
      hearingDay: { $set: action.payload.hearingDay },
      hearings: { $set: action.payload.hearings }
    });
  case ACTIONS.RECEIVE_HEARING:
    return update(state, {
      hearings: {
        [action.payload.hearing.externalId]: {
          $set: action.payload.hearing
        }
      }
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
  default:
    return state;
  }
};

export default dailyDocketReducer;
