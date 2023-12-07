import { ACTIONS } from './reviewPackageConstants';

export const setCorrespondence = (correspondence) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_CORRESPONDENCE,
      payload: {
        correspondence
      }
    });
  };

export const setCorrespondenceDocuments = (correspondenceDocuments) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_CORRESPONDENCE_DOCUMENTS,
      payload: {
        correspondenceDocuments
      }
    });
  };

export const setPackageDocumentType = (packageDocumentType) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_PACKAGE_DOCUMENT_TYPE,
      payload: {
        packageDocumentType
      }
    });
  };

export const updateCmpInformation = (packageDocumentType, date) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_CMP_INFORMATION,
      payload: {
        packageDocumentType,
        date
      }
    });
  };
