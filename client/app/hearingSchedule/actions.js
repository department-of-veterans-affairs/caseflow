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
