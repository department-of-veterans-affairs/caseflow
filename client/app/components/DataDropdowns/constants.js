import _ from 'lodash';

import HEARING_ROOMS_LIST from '../../../constants/HEARING_ROOMS_LIST';

export const HEARING_ROOM_OPTIONS = [
  {
    label: 'None',
    value: null
  }
].concat(
  _.map(HEARING_ROOMS_LIST, (value, key) => ({
    label: value.label,
    value: key.toString()
  }))
);

export const TIME_SLOT_LENGTHS = [
  {
    value: 60,
    label: '60 minutes'
  },
  {
    value: 45,
    label: '45 minutes'
  },
  {
    value: 30,
    label: '30 minutes'
  },
];
