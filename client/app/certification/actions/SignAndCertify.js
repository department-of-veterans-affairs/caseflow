import * as Constants from '../constants/constants';
import ApiUtil from '../../util/ApiUtil';


export const updateProgressBar = () => ({
  type: Constants.UPDATE_PROGRESS_BAR,
  payload: {
    currentSection: Constants.progressBarSections.SIGN_AND_CERTIFY
  }
});

export const changeCertifyingOfficialName = (certifyingOfficialName) => ({
  type: Constants.CHANGE_CERTIFYING_OFFICIAL_NAME,
  payload: {
    certifyingOfficialName
  }
});

export const changeCertifyingOfficialTitle = (certifyingOfficialTitle) => ({
  type: Constants.CHANGE_CERTIFYING_OFFICIAL_TITLE,
  payload: {
    certifyingOfficialTitle
  }
});

export const changeCertifyingOfficialTitleOther = (certifyingOfficialTitleOther) => ({
  type: Constants.CHANGE_CERTIFYING_OFFICIAL_TITLE_OTHER,
  payload: {
    certifyingOfficialTitleOther
  }
});

export const handleServerError = () => ({
  type: Constants.HANDLE_SERVER_ERROR
});

export const certificationUpdateSuccess = () => ({
  type: Constants.CERTIFICATION_UPDATE_SUCCESS
});

export const certificationUpdateStart = (params, dispatch) => {
  // Translate camelcase React names into snake case
  // Rails key names.
  /* eslint-disable camelcase */

  let certifyingOfficialTitle;

  if (params.certifyingOfficialTitle === Constants.certifyingOfficialTitles.OTHER) {
    certifyingOfficialTitle = params.certifyingOfficialTitleOther;
  } else {
    certifyingOfficialTitle = params.certifyingOfficialTitle;
  }

  const update = {
    certifying_official_name: params.certifyingOfficialName,
    certifying_official_title: certifyingOfficialTitle
  };

  /* eslint-enable "camelcase" */

  ApiUtil.post(`/certifications/${params.vacolsId}/certify_v2`, { data: { update } }).
    then(() => {
      dispatch(certificationUpdateSuccess());
    }, (err) => {
      dispatch(handleServerError(err));
    });

  // This is to save SignAndCertify form values (different than db values) in case going back
  const update_state = {
    certifying_official_name: params.certifyingOfficialName,
    certifying_official_title: params.certifyingOfficialTitle,
    certifying_official_title_other: params.certifyingOfficialTitleOther
  };

  return {
    type: Constants.CERTIFICATION_UPDATE_REQUEST,
    payload: {
      update_state
    }
  };
};

