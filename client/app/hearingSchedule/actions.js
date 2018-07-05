import { ACTIONS } from './constants';

export const onReceivePastUploads = (pastUploads) => ({
  type: ACTIONS.RECEIVE_PAST_UPLOADS,
  payload: {
    pastUploads
  }
});

export const onFileTypeChange = (fileType) => ({
  type: ACTIONS.FILE_TYPE_CHANGE,
  payload: {
    fileType
  }
});
