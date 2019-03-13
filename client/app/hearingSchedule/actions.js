import { ACTIONS } from './constants';

export const onReceivePastUploads = (pastUploads) => ({
  type: ACTIONS.RECEIVE_PAST_UPLOADS,
  payload: {
    pastUploads
  }
});

export const onReceiveSchedulePeriod = (schedulePeriod) => ({
  type: ACTIONS.RECEIVE_SCHEDULE_PERIOD,
  payload: {
    schedulePeriod
  }
});

export const onReceiveDailyDocket = (dailyDocket, hearings, hearingDayOptions) => ({
  type: ACTIONS.RECEIVE_DAILY_DOCKET,
  payload: {
    dailyDocket,
    hearings,
    hearingDayOptions
  }
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

export const onCancelHearingUpdate = (hearing) => ({
  type: ACTIONS.CANCEL_HEARING_UPDATE,
  payload: {
    hearing
  }
});

export const onReceiveUpcomingHearingDays = (upcomingHearingDays) => ({
  type: ACTIONS.RECEIVE_UPCOMING_HEARING_DAYS,
  payload: {
    upcomingHearingDays
  }
});

export const onReceiveAppealsReadyForHearing = (appeals) => ({
  type: ACTIONS.RECEIVE_APPEALS_READY_FOR_HEARING,
  payload: {
    appeals
  }
});

export const onHearingNotesUpdate = (hearingId, notes) => ({
  type: ACTIONS.HEARING_NOTES_UPDATE,
  payload: {
    hearingId,
    notes
  }
});

export const onTranscriptRequestedUpdate = (hearingId, transcriptRequested) => ({
  type: ACTIONS.TRANSCRIPT_REQUESTED_UPDATE,
  payload: {
    hearingId,
    transcriptRequested
  }
});

export const onHearingDispositionUpdate = (hearingId, disposition) => ({
  type: ACTIONS.HEARING_DISPOSITION_UPDATE,
  payload: {
    hearingId,
    disposition
  }
});

export const onHearingDateUpdate = (hearingId, date) => ({
  type: ACTIONS.HEARING_DATE_UPDATE,
  payload: {
    hearingId,
    date
  }
});

export const onHearingLocationUpdate = (hearingId, location) => ({
  type: ACTIONS.HEARING_LOCATION_UPDATE,
  payload: {
    hearingId,
    location
  }
});

export const onHearingRegionalOfficeUpdate = (hearingId, regionalOffice) => ({
  type: ACTIONS.HEARING_REGIONAL_OFFICE_UPDATE,
  payload: {
    hearingId,
    regionalOffice
  }
});

export const onHearingTimeUpdate = (hearingId, time) => ({
  type: ACTIONS.HEARING_TIME_UPDATE,
  payload: {
    hearingId,
    time
  }
});

export const onHearingOptionalTime = (hearingId, optionalTime) => ({
  type: ACTIONS.HEARING_OPTIONAL_TIME,
  payload: {
    hearingId,
    optionalTime
  }
});

export const onInvalidForm = (hearingId, invalid) => ({
  type: ACTIONS.INVALID_FORM,
  payload: {
    hearingId,
    invalid
  }
});

export const onSelectedHearingDayChange = (selectedHearingDay) => ({
  type: ACTIONS.SELECTED_HEARING_DAY_CHANGE,
  payload: {
    selectedHearingDay
  }
});

export const onSchedulePeriodError = (error) => ({
  type: ACTIONS.SCHEDULE_PERIOD_ERROR,
  payload: {
    error
  }
});

export const removeSchedulePeriodError = () => ({
  type: ACTIONS.REMOVE_SCHEDULE_PERIOD_ERROR
});

export const onFileTypeChange = (fileType) => ({
  type: ACTIONS.FILE_TYPE_CHANGE,
  payload: {
    fileType
  }
});

export const onReceiveHearingSchedule = (hearingSchedule) => ({
  type: ACTIONS.RECEIVE_HEARING_SCHEDULE,
  payload: {
    hearingSchedule
  }
});

export const setVacolsUpload = () => ({
  type: ACTIONS.SET_VACOLS_UPLOAD
});

export const onRoCoStartDateChange = (startDate) => ({
  type: ACTIONS.RO_CO_START_DATE_CHANGE,
  payload: {
    startDate
  }
});

export const onRoCoEndDateChange = (endDate) => ({
  type: ACTIONS.RO_CO_END_DATE_CHANGE,
  payload: {
    endDate
  }
});

export const onRoCoFileUpload = (file) => ({
  type: ACTIONS.RO_CO_FILE_UPLOAD,
  payload: {
    file
  }
});

export const onJudgeStartDateChange = (startDate) => ({
  type: ACTIONS.JUDGE_START_DATE_CHANGE,
  payload: {
    startDate
  }
});

export const onJudgeEndDateChange = (endDate) => ({
  type: ACTIONS.JUDGE_END_DATE_CHANGE,
  payload: {
    endDate
  }
});

export const updateUploadFormErrors = (errors) => ({
  type: ACTIONS.UPDATE_UPLOAD_FORM_ERRORS,
  payload: {
    errors
  }
});

export const updateRoCoUploadFormErrors = (errors) => ({
  type: ACTIONS.UPDATE_RO_CO_UPLOAD_FORM_ERRORS,
  payload: {
    errors
  }
});

export const updateJudgeUploadFormErrors = (errors) => ({
  type: ACTIONS.UPDATE_JUDGE_UPLOAD_FORM_ERRORS,
  payload: {
    errors
  }
});

export const unsetUploadErrors = () => ({
  type: ACTIONS.UNSET_UPLOAD_ERRORS
});

export const onViewStartDateChange = (viewStartDate) => ({
  type: ACTIONS.VIEW_START_DATE_CHANGE,
  payload: {
    viewStartDate
  }
});

export const onViewEndDateChange = (viewEndDate) => ({
  type: ACTIONS.VIEW_END_DATE_CHANGE,
  payload: {
    viewEndDate
  }
});

export const onJudgeFileUpload = (file) => ({
  type: ACTIONS.JUDGE_FILE_UPLOAD,
  payload: {
    file
  }
});

export const toggleUploadContinueLoading = () => ({
  type: ACTIONS.TOGGLE_UPLOAD_CONTINUE_LOADING
});

export const onClickConfirmAssignments = () => ({
  type: ACTIONS.CLICK_CONFIRM_ASSIGNMENTS
});

export const onClickCloseModal = () => ({
  type: ACTIONS.CLICK_CLOSE_MODAL
});

export const onConfirmAssignmentsUpload = () => ({
  type: ACTIONS.CONFIRM_ASSIGNMENTS_UPLOAD
});

export const unsetSuccessMessage = () => ({
  type: ACTIONS.UNSET_SUCCESS_MESSAGE
});

export const toggleTypeFilterVisibility = () => ({
  type: ACTIONS.TOGGLE_TYPE_FILTER_DROPDOWN
});

export const toggleLocationFilterVisibility = () => ({
  type: ACTIONS.TOGGLE_LOCATION_FILTER_DROPDOWN
});

export const toggleVljFilterVisibility = () => ({
  type: ACTIONS.TOGGLE_VLJ_FILTER_DROPDOWN
});

export const selectRequestType = (requestType) => ({
  type: ACTIONS.SELECT_REQUEST_TYPE,
  payload: {
    requestType
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

export const onHearingDayModified = (hearingDayModified) => ({
  type: ACTIONS.HEARING_DAY_MODIFIED,
  payload: {
    hearingDayModified
  }
});

export const onClickRemoveHearingDay = () => ({
  type: ACTIONS.ON_CLICK_REMOVE_HEARING_DAY
});

export const onCancelRemoveHearingDay = () => ({
  type: ACTIONS.CANCEL_REMOVE_HEARING_DAY
});

export const onSuccessfulHearingDayDelete = (date) => ({
  type: ACTIONS.SUCCESSFUL_HEARING_DAY_DELETE,
  payload: {
    date
  }
});

export const onResetDeleteSuccessful = () => ({
  type: ACTIONS.RESET_DELETE_SUCCESSFUL
});

export const onAssignHearingRoom = (roomRequired) => ({
  type: ACTIONS.ASSIGN_HEARING_ROOM,
  payload: {
    roomRequired
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

export const handleDailyDocketServerError = (err) => ({
  type: ACTIONS.HANDLE_DAILY_DOCKET_SERVER_ERROR,
  payload: {
    err
  }
});

export const onResetDailyDocketAfterError = () => ({
  type: ACTIONS.RESET_DAILY_DOCKET_AFTER_SERVER_ERROR
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
