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

export const setLoadedVacolsId = (vacolsId) => ({
  type: Constants.SET_LOADED_APPEAL_ID,
  payload: {
    vacolsId
  }
});

export const updateFilteredIds = () => ({
  type: Constants.UPDATE_FILTERED_DOC_IDS
});

export const onReceiveDocs = (documents, vacolsId) =>
  (dispatch) => {
    dispatch({
      type: Constants.RECEIVE_DOCUMENTS,
      payload: {
        documents
      }
    });
    dispatch(updateFilteredIds());
    dispatch(collectAllTags(documents));
    dispatch(setViewedAssignment(vacolsId));
    dispatch(setLoadedVacolsId(vacolsId));
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
