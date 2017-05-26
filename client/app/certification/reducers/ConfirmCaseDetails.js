import * as Constants from '../constants/constants';

export const changeRepresentativeType = (state, action) => {
  const update = {};

  update.representativeType = action.payload.representativeType;
  // if we changed the type to something other than "Other",
  // erase the other representative type if it was specified.
  if (state.representativeType !== Constants.representativeTypes.OTHER) {
    update.otherRepresentativeType = null;
  }

  return Object.assign({}, state, update);
};

export const changeRepresentativeName = (state, action) => {
  return Object.assign({}, state, {
    representativeName: action.payload.representativeName
  });
};

export const changeOtherRepresentativeType = (state, action) => {
  return Object.assign({}, state, {
    otherRepresentativeType: action.payload.otherRepresentativeType
  });
};

export const changePoaMatches = (state, action) => {
  return Object.assign({}, state, {
    poaMatches: action.payload.poaMatches
  });
};

export const changePoaCorrectLocation = (state, action) => {
  return Object.assign({}, state, {
    poaCorrectLocation: action.payload.poaCorrectLocation
  });
};
