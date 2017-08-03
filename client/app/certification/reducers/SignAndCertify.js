import * as CertificationReducers from './Certification';

export const changeCertifyingOfficialName = (state, action) => {
  const updatedErroredFields = CertificationReducers.clearErroredField('certifyingOfficialName', state);

  const update = {
    certifyingOfficialName: action.payload.certifyingOfficialName,
    erroredFields: updatedErroredFields
  };

  return Object.assign({}, state, update);
};

export const changeCertifyingOfficialTitle = (state, action) => {
  const updatedErroredFields = CertificationReducers.clearErroredField('certifyingOfficialTitle', state);

  const update = {
    certifyingOfficialTitle: action.payload.certifyingOfficialTitle,
    erroredFields: updatedErroredFields
  };

  return Object.assign({}, state, update);
};

export const changeCertifyingOfficialTitleOther = (state, action) => {
  const updatedErroredFields = CertificationReducers.clearErroredField('certifyingOfficialTitleOther', state);

  const update = {
    certifyingOfficialTitleOther: action.payload.certifyingOfficialTitleOther,
    erroredFields: updatedErroredFields
  };

  return Object.assign({}, state, update);
};
