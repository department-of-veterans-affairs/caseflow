import { ACTIONS } from '../constants';

export const onReceiveDailyDocket = (hearingDay, hearings) => ({
  type: ACTIONS.RECEIVE_DAILY_DOCKET,
  payload: {
    hearingDay,
    hearings
  }
});

export const onDisplayLockModal = () => ({
  type: ACTIONS.DISPLAY_LOCK_MODAL
});

export const onCancelDisplayLockModal = () => ({
  type: ACTIONS.CANCEL_DISPLAY_LOCK_MODAL
});

export const onUpdateLock = (lock) => ({
  type: ACTIONS.UPDATE_LOCK,
  payload: {
    lock
  }
});

export const onResetLockSuccessMessage = () => ({
  type: ACTIONS.RESET_LOCK_SUCCESS_MESSAGE
});

export const handleLockHearingServerError = (err) => ({
  type: ACTIONS.HANDLE_LOCK_HEARING_SERVER_ERROR,
  payload: {
    err
  }
});

export const onResetLockHearingAfterError = () => ({
  type: ACTIONS.RESET_LOCK_HEARING_SERVER_ERROR
});

export const onClickRemoveHearingDay = () => ({
  type: ACTIONS.ON_CLICK_REMOVE_HEARING_DAY
});

export const onCancelRemoveHearingDay = () => ({
  type: ACTIONS.CANCEL_REMOVE_HEARING_DAY
});

export const handleDailyDocketServerError = (err) => ({
  type: ACTIONS.HANDLE_DAILY_DOCKET_SERVER_ERROR,
  payload: {
    err
  }
});

export const onResetDailyDocketAfterError = () => ({
  type: ACTIONS.RESET_DAILY_DOCKET_AFTER_SERVER_ERROR
});

export const onReceiveSavedHearing = (hearing) => ({
  type: ACTIONS.RECEIVE_SAVED_HEARING,
  payload: {
    hearing
  }
});

export const onResetSaveSuccessful = () => ({
  type: ACTIONS.RESET_SAVE_SUCCESSFUL
});

export const onUpdateDocketHearing = (hearingId, values) => ({
  type: ACTIONS.UPDATE_DOCKET_HEARING,
  payload: {
    hearingId,
    values
  }
});

export const onHearingDayModified = (hearingDayModified) => ({
  type: ACTIONS.HEARING_DAY_MODIFIED,
  payload: {
    hearingDayModified
  }
});

export const selectVlj = (vlj) => ({
  type: ACTIONS.SELECT_VLJ,
  payload: {
    vlj
  }
});

export const selectHearingCoordinator = (coordinator) => ({
  type: ACTIONS.SELECT_COORDINATOR,
  payload: {
    coordinator
  }
});

export const selectHearingRoom = (hearingRoom) => ({
  type: ACTIONS.SELECT_HEARING_ROOM,
  payload: {
    hearingRoom
  }
});

export const setNotes = (notes) => ({
  type: ACTIONS.SET_NOTES,
  payload: {
    notes
  }
});

export const onSuccessfulHearingDayCreate = (date) => ({
  type: ACTIONS.SUCCESSFUL_HEARING_DAY_CREATE,
  payload: {
    date
  }
});

export const onSuccessfulHearingDayDelete = (date) => ({
  type: ACTIONS.SUCCESSFUL_HEARING_DAY_DELETE,
  payload: {
    date
  }
});
