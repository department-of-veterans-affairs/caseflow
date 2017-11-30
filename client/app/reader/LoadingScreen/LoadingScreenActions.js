import * as Constants from '../constants';
import { collectAllTags } from '../PdfViewer/PdfViewerActions';
import { setViewedAssignment } from '../CaseSelect/CaseSelectActions';

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
    dispatch(setViewedAssignment(vacolsId));
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

export const onReceiveManifests = (manifestVbmsFetchedAt, manifestVvaFetchedAt) => ({
  type: Constants.RECEIVE_MANIFESTS,
  payload: { manifestVbmsFetchedAt,
    manifestVvaFetchedAt }
});
