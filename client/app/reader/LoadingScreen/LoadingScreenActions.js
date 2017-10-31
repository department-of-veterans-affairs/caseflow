import * as Constants from '../constants';
import { collectAllTags } from '../actions';

export const onInitialDataLoadingFail = (value = true) => ({
  type: Constants.REQUEST_INITIAL_DATA_FAILURE,
  payload: { value }
});

export const onInitialCaseLoadingFail = (value = true) => ({
  type: Constants.REQUEST_INITIAL_CASE_FAILURE,
  payload: { value }
});

export const onReceiveDocs = (documents, vacolsId) =>
  (dispatch) => {
    dispatch(collectAllTags(documents));
    dispatch({
      type: Constants.RECEIVE_DOCUMENTS,
      payload: {
        documents,
        vacolsId
      }
    });
  };

export const onReceiveAnnotations = (annotations) => ({
  type: Constants.RECEIVE_ANNOTATIONS,
  payload: { annotations }
});

export const onReceiveAssignments = (assignments) => ({
  type: Constants.RECEIVE_ASSIGNMENTS,
  payload: { assignments }
});

export const onReceiveManifests = (manifestVbmsFetchedAt, manifestVvaFetchedAt) => ({
  type: Constants.RECEIVE_MANIFESTS,
  payload: { manifestVbmsFetchedAt,
    manifestVvaFetchedAt }
});

export const onInitialDataStillLoading = (value = true) => ({
  type: Constants.REQUEST_INITIAL_DATA_LOADING,
  payload: { value }
});
