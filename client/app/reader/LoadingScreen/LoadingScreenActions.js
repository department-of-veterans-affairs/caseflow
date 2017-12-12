import * as Constants from '../constants';
import { collectAllTags } from '../PdfViewer/PdfViewerActions';
import { setViewedAssignment } from '../CaseSelect/CaseSelectActions';
import { updateFilteredIdsAndDocs } from '../commonActions';

export const setLoadedVacolsId = (vacolsId) => ({
  type: Constants.SET_LOADED_APPEAL_ID,
  payload: {
    vacolsId
  }
});

export const onReceiveDocs = (documents, vacolsId) =>
  (dispatch) => {
    dispatch({
      type: Constants.RECEIVE_DOCUMENTS,
      payload: {
        documents
      }
    });
    dispatch(updateFilteredIdsAndDocs());
    dispatch(collectAllTags(documents));
    dispatch(setViewedAssignment(vacolsId));
    dispatch(setLoadedVacolsId(vacolsId));
  };

export const onReceiveManifests = (manifestVbmsFetchedAt, manifestVvaFetchedAt) => ({
  type: Constants.RECEIVE_MANIFESTS,
  payload: { manifestVbmsFetchedAt,
    manifestVvaFetchedAt }
});
