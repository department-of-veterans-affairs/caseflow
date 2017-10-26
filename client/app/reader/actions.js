/* eslint-disable max-lines */

import * as Constants from './constants';
import _ from 'lodash';
import { CATEGORIES } from './analytics';

export const handleSetLastRead = (docId) => ({
  type: Constants.LAST_READ_DOCUMENT,
  payload: {
    docId
  }
});
