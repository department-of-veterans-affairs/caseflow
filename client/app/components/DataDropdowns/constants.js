import _ from 'lodash';

import HEARING_ROOMS_LIST from '../../../constants/HEARING_ROOMS_LIST.json';

export const HEARING_ROOM_OPTIONS = _.map(HEARING_ROOMS_LIST, (value, key) => ({
  label: value.label,
  value: parseInt(key, 10)
}));
