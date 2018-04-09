import ApiUtil from '../../util/ApiUtil';
import * as Constants from './actionTypes';
import _ from 'lodash';

export const clearCaseListSearch = () => ({
  type: Constants.CLEAR_CASE_LIST_SEARCH
});

export const setCaseListSearch = (searchQuery) => ({
  type: Constants.SET_CASE_LIST_SEARCH,
  payload: { searchQuery }
});

export const setShouldUseQueueSearch = (bool) => ({
  type: Constants.SET_SHOULD_USE_QUEUE_SEARCH,
  payload: { bool }
});

export const requestAppealUsingVeteranId = () => ({
  type: Constants.REQUEST_APPEAL_USING_VETERAN_ID
});

export const fetchedNoAppealsUsingVeteranId = (searchQuery) => ({
  type: Constants.RECEIVED_NO_APPEALS_USING_VETERAN_ID,
  payload: { searchQuery }
});

export const onReceiveAppealsUsingVeteranId = (appeals) => ({
  type: Constants.RECEIVED_APPEALS_USING_VETERAN_ID_SUCCESS,
  payload: { appeals }
});

export const fetchAppealUsingVeteranIdFailed = () => ({
  type: Constants.RECEIVED_APPEALS_USING_VETERAN_ID_FAILURE
});

export const increaseVeteranDocumentCountBy = (count) => ({
  type: Constants.INCREASE_VETERAN_DOCUMENT_COUNT_BY,
  payload: { count }
});

export const fetchDocumentCountForVeteran = (appeals) => (dispatch) => {
  appeals.forEach((appeal) => {
    const requestOptions = {
      withCredentials: true,
      timeout: true,
      headers: { 'FILE-NUMBER': appeal.attributes.vbms_id }
    };

    ApiUtil.get(appeal.attributes.number_of_documents_url, requestOptions).
      then((response) => {
        const resp = JSON.parse(response.text);

        dispatch(increaseVeteranDocumentCountBy(resp.data.attributes.documents.length));
      });
  });
};

export const fetchAppealsUsingVeteranId = (veteranId) =>
  (dispatch) => {
    ApiUtil.get('/appeals', {
      headers: { 'veteran-id': veteranId }
    }).
      then((response) => {
        const returnedObject = JSON.parse(response.text);

        const shouldUseAppealSearch = Object.prototype.hasOwnProperty.call(returnedObject, 'shouldUseAppealSearch') &&
          returnedObject.shouldUseAppealSearch;

        dispatch(setShouldUseQueueSearch(shouldUseAppealSearch));

        // TODO: AppealsController.index returns the appeals with the extraneous data element. Remove this
        // when we change the data structure we return to collapse the data element.
        // { appeals: { data: [ {...}, {...}, {...} ] } }
        const appeals = returnedObject.appeals.data;

        if (_.size(appeals) === 0) {
          dispatch(fetchedNoAppealsUsingVeteranId(veteranId));
        } else {
          dispatch(onReceiveAppealsUsingVeteranId(appeals));
          dispatch(fetchDocumentCountForVeteran(appeals));
        }
      }, () => {
        dispatch(fetchAppealUsingVeteranIdFailed());
      });
  };
