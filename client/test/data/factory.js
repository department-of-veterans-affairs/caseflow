/* eslint camelcase: 0 */
import { isFunction, times } from 'lodash';

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

export const createOrg = (count = 1, values = {}) => {
  return times(count).map((index) => ({
    id: (values.startingId || 1) + index,
    accepts_priority_pushed_cases: values.accepts_priority_pushed_cases ?? true,
    name: (isFunction(values.name) ? values.name() : (values?.name ?? `OrgName ${index}`)),
    participant_id: (isFunction(values.participant_id) ? values.participant_id() : (values?.participant_id ?? null)),
    type: values.type ?? 'Organization',
    url: (isFunction(values.url) ? values.url() : (values?.url ?? `org-${index}`)),
    user_admin_path: values.user_admin_path ?? null,
    current_user_can_toggle_priority_pushed_cases: values.current_user_can_toggle_priority_pushed_cases ?? true
  }));
};

