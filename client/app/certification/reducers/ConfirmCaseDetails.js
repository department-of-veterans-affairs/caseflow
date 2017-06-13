import * as Constants from '../constants/constants';

/* eslint max-statements: ["error", 14]*/
export const updateErroredFields = (fieldName, state) => {
  const index = state.erroredFields.indexOf(fieldName);
  const newErroredFields = state.erroredFields;

  if (index !== -1) {
    newErroredFields.splice(index, 1);
  }

  return newErroredFields;
};

export const changeRepresentativeType = (state, action) => {
  const update = {};
  const updatedErroredFields = updateErroredFields('representativeType', state);

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
  let updatedErroredFields = [];

  if (state.erroredFields.indexOf('representativeName') === -1) {
    updatedErroredFields = updateErroredFields('representativeNameLength', state);
  } else {
    updatedErroredFields = updateErroredFields('representativeName', state);
  }

  return Object.assign({}, state, {
    representativeName: action.payload.representativeName,
    erroredFields: updatedErroredFields
  });
};

export const changeOrganizationName = (state, action) => {
  const updatedErroredFields = updateErroredFields('organizationName', state);

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
  const updatedErroredFields = updateErroredFields('poaMatches', state);

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
  const updatedErroredFields = updateErroredFields('poaCorrectLocation', state);

  const update = {
    poaCorrectLocation: action.payload.poaCorrectLocation,
    organizationName: null,
    representativeName: null,
    representativeType: null,
    erroredFields: updatedErroredFields
  };

  return Object.assign({}, state, update);
};
