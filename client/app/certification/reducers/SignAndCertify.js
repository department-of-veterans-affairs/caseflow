import * as CertificationReducers from './Certification';

export const changeSignAndCertifyForm = (state, action) => {
  const update = {};
  let key = Object.keys(action.payload)[0];

  update[key] = action.payload[key];
  update.erroredFields = CertificationReducers.clearErroredField(key, state);

  return Object.assign({}, state, update);
};
