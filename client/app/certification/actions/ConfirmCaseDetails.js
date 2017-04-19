import * as Constants from '../constants/constants';
import ApiUtil from '../../util/ApiUtil';

export const updateProgressBar = () => ({
  type: Constants.UPDATE_PROGRESS_BAR,
  payload: {
    currentSection: Constants.progressBarSections.CONFIRM_CASE_DETAILS
  }
});

export const changeRepresentativeName = (representativeName) => ({
  type: Constants.CHANGE_REPRESENTATIVE_NAME,
  payload: {
    representativeName
  }
});

export const changeRepresentativeType = (representativeType) => ({
  type: Constants.CHANGE_REPRESENTATIVE_TYPE,
  payload: {
    representativeType
  }
});

export const changeOtherRepresentativeType = (otherRepresentativeType) => ({
  type: Constants.CHANGE_OTHER_REPRESENTATIVE_TYPE,
  payload: {
    otherRepresentativeType
  }
});

export const failValidation = (invalidFields) => ({
  type: Constants.FAILED_VALIDATION,
  payload: {
    validationFailed: true,
    invalidFields
  }
});

export const certificationUpdateFailure = () => ({
  type: Constants.CERTIFICATION_UPDATE_FAILURE
});

export const certificationUpdateSuccess = () => ({
  type: Constants.CERTIFICATION_UPDATE_SUCCESS
});

export const certificationUpdateStart = (params, dispatch) => {
  // On the backend, we only have one column for "representativeType",
  // and we don't store "Other" in that column.
  // TODO (alex): create column for this?
  const type = params.representativeType === Constants.representativeTypes.OTHER ?
    params.otherRepresentativeType : params.representativeType;
  const name = params.representativeName;

  // Translate camelcase React names into snake case
  // Rails key names.
  /* eslint-disable camelcase */
  const update = {
    representative_type: type,
    representative_name: name
  };
  /* eslint-enable "camelcase" */

  ApiUtil.put(`/certifications/${params.vacolsId}/update_v2`, { data: { update } }).
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

