/* eslint camelcase: 0 */
import { times } from 'lodash';

export const createUser = (count = 1, values = {}) => {
  return times(count).map((index) => ({
    css_id: values.css_id || `123-${index}`,
    id: (values.startingId || 1) + index,
    station_id: '456'
  }));
};

export const createAppeal = (count = 1, values = {}) => {
  return times(count).map((index) => ({
    id: (values.startingId || 1) + 1,
    vacols_id: `123-${index}`,
    vbms_id: `456-${index}`
  }));
};

export const createTask = (count = 1, values = {}) => {
  return times(count).map(() => ({
    appeal: values.appeal || createAppeal()[0],
    type: values.type || 'EstablishClaim',
    user: values.user || createUser()[0]
  }));
};
