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

export const changeOrganizationName = (organizationName) => ({
  type: Constants.CHANGE_ORGANIZATION_NAME,
  payload: {
    organizationName
  }
});

export const changeOtherRepresentativeType = (otherRepresentativeType) => ({
  type: Constants.CHANGE_OTHER_REPRESENTATIVE_TYPE,
  payload: {
    otherRepresentativeType
  }
});

export const changePoaMatches = (poaMatches) => ({
  type: Constants.CHANGE_POA_MATCHES,
  payload: {
    poaMatches
  }
});

export const changePoaCorrectLocation = (poaCorrectLocation) => ({
  type: Constants.CHANGE_POA_CORRECT_LOCATION,
  payload: {
    poaCorrectLocation
  }
});

export const handleServerError = () => ({
  type: Constants.HANDLE_SERVER_ERROR
});

export const certificationUpdateSuccess = () => ({
  type: Constants.CERTIFICATION_UPDATE_SUCCESS
});

export const certificationUpdateStart = (params, dispatch) => {
  const type = params.representativeType;
  const name = params.representativeName;
  const poaMatches = params.poaMatches === Constants.poaMatches.MATCH;
  const poaCorrectInVacols = params.poaCorrectLocation === Constants.poaCorrectLocation.VACOLS;
  const poaCorrectInBgs = params.poaCorrectLocation === Constants.poaCorrectLocation.VBMS;

  // Translate camelcase React names into snake case
  // Rails key names.
  /* eslint-disable camelcase */
  const update = {
    representative_type: type,
    representative_name: name,
    poa_matches: poaMatches,
    poa_correct_in_vacols: poaCorrectInVacols,
    poa_correct_in_bgs: poaCorrectInBgs
  };

  /* eslint-enable camelcase */

  ApiUtil.put(`/certifications/${params.vacolsId}/update_v2`, { data: { update } }).
    then(() => {
      dispatch(certificationUpdateSuccess());
    }, (err) => {
      dispatch(handleServerError(err));
    });

  return {
    type: Constants.CERTIFICATION_UPDATE_REQUEST,
    payload: {
      update
    }
  };
};

