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

export const onSchedulePeriodError = () => ({
  type: ACTIONS.SCHEDULE_PERIOD_ERROR
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
