import { combineReducers } from 'redux';
import { timeFunction } from 'app/util/PerfDebug';

import reader from 'store/reader';

const rootReducer = combineReducers({
  reader,
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
