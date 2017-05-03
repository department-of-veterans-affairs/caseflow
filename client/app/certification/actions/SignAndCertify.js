import * as Constants from '../constants/constants';
import ApiUtil from '../../util/ApiUtil';

export const updateProgressBar = () => ({
  type: Constants.UPDATE_PROGRESS_BAR,
  payload: {
    currentSection: Constants.progressBarSections.SIGN_AND_CERTIFY
  }
});

export const onSignAndCertifyFormChange = (fieldName, value) => ({
  type: Constants.CHANGE_SIGN_AND_CERTIFY_FORM,
  payload: {
    [fieldName]: value
  }
});

export const certificationUpdateFailure = () => ({
  type: Constants.CERTIFICATION_UPDATE_FAILURE
});

export const certificationUpdateSuccess = () => ({
  type: Constants.CERTIFICATION_UPDATE_SUCCESS
});

export const certificationUpdateStart = (params, dispatch) => {
  // Translate camelcase React names into snake case
  // Rails key names.
  /* eslint-disable camelcase */

  const update = {
    certifying_office: params.certifyingOffice,
    certifying_username: params.certifyingUsername,
    certifying_official_name: params.certifyingOfficialName,
    certifying_official_title: params.certifyingOfficialTitle,
    certification_date: params.certificationDate
  };

  /* eslint-enable "camelcase" */

  ApiUtil.post(`/certifications/${params.vacolsId}/certify_v2`, { data: { update } }).
    then(() => {
      dispatch(certificationUpdateSuccess());
    }, (err) => {
      dispatch(certificationUpdateFailure(err));
    });

  return {
    type: Constants.CERTIFICATION_UPDATE_REQUEST,
    payload: {
      update
    }
  };
};

