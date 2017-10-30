import ApiUtil from '../../util/ApiUtil';
import { CATEGORIES, ENDPOINT_NAMES } from '../analytics';
import * as Constants from '../constants';
import _ from 'lodash';

// CaseSelect search

export const clearCaseSelectSearch = () => ({
  type: Constants.CLEAR_CASE_SELECT_SEARCH
});

export const setCaseSelectSearch = (searchQuery) => ({
  type: Constants.SET_CASE_SELECT_SEARCH,
  payload: {
    searchQuery
  }
});

export const caseSelectAppeal = (appeal) => ({
  type: Constants.CASE_SELECT_APPEAL,
  payload: { appeal }
});

export const caseSelectModalSelectVacolsId = (vacolsId) => ({
  type: Constants.CASE_SELECT_MODAL_APPEAL_VACOLS_ID,
  payload: {
    vacolsId
  }
});

export const requestAppealUsingVeteranId = () => ({
  type: Constants.REQUEST_APPEAL_USING_VETERAN_ID,
  meta: {
    analytics: {
      category: CATEGORIES.CASE_SELECTION_PAGE,
      action: 'case-search'
    }
  }
});

export const fetchedNoAppealsUsingVeteranId = () => ({
  type: Constants.RECEIVED_NO_APPEALS_USING_VETERAN_ID
});

export const onReceiveAppealsUsingVeteranId = (appeals) => ({
  type: Constants.RECEIVE_APPEALS_USING_VETERAN_ID_SUCCESS,
  payload: { appeals }
});

export const fetchAppealUsingVeteranIdFailed = () => ({
  type: Constants.RECEIVE_APPEALS_USING_VETERAN_ID_FAILURE
});

export const fetchAppealUsingVeteranId = (veteranId) =>
  (dispatch) => {
    dispatch(requestAppealUsingVeteranId());
    ApiUtil.get('/reader/appeal/veteran-id?json', {
      headers: { 'veteran-id': veteranId }
    },
    ENDPOINT_NAMES.APPEAL_DETAILS_BY_VET_ID).
      then((response) => {
        const returnedObject = JSON.parse(response.text);

        if (_.size(returnedObject.appeals) === 0) {
          dispatch(fetchedNoAppealsUsingVeteranId());
        } else {
          dispatch(onReceiveAppealsUsingVeteranId(returnedObject.appeals));
        }
      }, () => dispatch(fetchAppealUsingVeteranIdFailed()));
  };
