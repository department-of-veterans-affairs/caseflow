import * as Constants from '../constants/constants';
import * as CertificationReducers from './Certification';

/* eslint max-statements: ["error", 14]*/
export const changeRepresentativeType = (state, action) => {
  const update = {};
  const updatedErroredFields = CertificationReducers.clearErroredField('representativeType', state);

  update.erroredFields = updatedErroredFields;
  update.representativeType = action.payload.representativeType;
  // if we changed the type to something other than "Other",
  // erase the other representative type if it was specified.
  if (state.representativeType !== Constants.representativeTypes.OTHER) {
    update.otherRepresentativeType = null;
  }
  if (state.representativeType === Constants.representativeTypes.ORGANIZATION) {
    update.organizationName = null;
    update.representativeName = null;
  }

  return Object.assign({}, state, update);
};

export const changeRepresentativeName = (state, action) => {
  let updatedErroredFields = state.erroredFields || [];

  if (updatedErroredFields.indexOf('representativeName') === -1) {
    updatedErroredFields = CertificationReducers.clearErroredField('representativeNameLength', state);
  } else {
    updatedErroredFields = CertificationReducers.clearErroredField('representativeName', state);
  }

  return Object.assign({}, state, {
    representativeName: action.payload.representativeName,
    erroredFields: updatedErroredFields
  });
};

export const changeOrganizationName = (state, action) => {
  const updatedErroredFields = CertificationReducers.clearErroredField('organizationName', state);

  return Object.assign({}, state, {
    organizationName: action.payload.organizationName,
    erroredFields: updatedErroredFields
  });
};

export const changeOtherRepresentativeType = (state, action) => {
  return Object.assign({}, state, {
    otherRepresentativeType: action.payload.otherRepresentativeType
  });
};

export const changePoaMatches = (state, action) => {
  const updatedErroredFields = CertificationReducers.clearErroredField('poaMatches', state);

  const update = {
    poaMatches: action.payload.poaMatches,
    poaCorrectLocation: null,
    organizationName: null,
    representativeName: null,
    representativeType: null,
    erroredFields: updatedErroredFields
  };

  return Object.assign({}, state, update);
};

export const changePoaCorrectLocation = (state, action) => {
  const updatedErroredFields = CertificationReducers.clearErroredField('poaCorrectLocation', state);

  const update = {
    poaCorrectLocation: action.payload.poaCorrectLocation,
    organizationName: null,
    representativeName: null,
    representativeType: null,
    erroredFields: updatedErroredFields
  };

  return Object.assign({}, state, update);
};
