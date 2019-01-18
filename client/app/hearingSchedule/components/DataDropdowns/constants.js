import _ from 'lodash';

import HEARING_ROOMS_LIST from '../../../../constants/HEARING_ROOMS_LIST.json';

export const ACTIONS = {
  RECEIVE_DROPDOWN_DATA: 'RECEIVE_DROPDOWN_DATA',
  FETCH_DROPDOWN_DATA: 'FETCH_DROPDOWN_DATA'
};

export const HEARING_ROOM_OPTIONS = _.map(HEARING_ROOMS_LIST, (value, key) => ({
  label: value.label,
  value: parseInt(key, 10)
}));
