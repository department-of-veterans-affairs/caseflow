import * as CertificationReducers from './Certification';

export const changeSignAndCertifyForm = (state, action) => {
  const update = {};

  for (const key of Object.keys(action.payload)) {
    update[key] = action.payload[key];
    update.erroredFields = CertificationReducers.clearErroredField(key, state);
  }

  return Object.assign({}, state, update);
};
