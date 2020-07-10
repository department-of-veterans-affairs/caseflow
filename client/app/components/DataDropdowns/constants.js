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
