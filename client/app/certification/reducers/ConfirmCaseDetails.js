import * as Constants from '../constants/constants';

export const changeRepresentativeType = (state, action) => {
  const update = {};

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
  return Object.assign({}, state, {
    representativeName: action.payload.representativeName
  });
};

export const changeOrganizationName = (state, action) => {
  return Object.assign({}, state, {
    organizationName: action.payload.organizationName
  });
};

export const changeOtherRepresentativeType = (state, action) => {
  return Object.assign({}, state, {
    otherRepresentativeType: action.payload.otherRepresentativeType
  });
};

export const changePoaMatches = (state, action) => {
  const update = {};

  update.poaMatches = action.payload.poaMatches;
  update.poaCorrectLocation = null;
  update.organizationName = null;
  update.representativeName = null;
  update.representativeType = null;

  return Object.assign({}, state, update);
};

export const changePoaCorrectLocation = (state, action) => {
  const update = {};

  update.poaCorrectLocation = action.payload.poaCorrectLocation;
  update.organizationName = null;
  update.representativeName = null;
  update.representativeType = null;


  return Object.assign({}, state, update);
};
