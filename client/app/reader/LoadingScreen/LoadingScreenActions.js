import * as Constants from '../constants';
import { collectAllTags } from '../PdfViewer/PdfViewerActions';
<<<<<<< HEAD
=======
import { setViewedAssignment } from '../CaseSelect/CaseSelectActions';
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b

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
<<<<<<< HEAD
=======
    dispatch(setViewedAssignment(vacolsId));
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
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

<<<<<<< HEAD
export const onReceiveAssignments = (assignments) => ({
  type: Constants.RECEIVE_ASSIGNMENTS,
  payload: { assignments }
});

=======
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
export const onReceiveManifests = (manifestVbmsFetchedAt, manifestVvaFetchedAt) => ({
  type: Constants.RECEIVE_MANIFESTS,
  payload: { manifestVbmsFetchedAt,
    manifestVvaFetchedAt }
});
