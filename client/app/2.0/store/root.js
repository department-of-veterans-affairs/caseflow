import { combineReducers } from 'redux';
import { timeFunction } from 'app/util/PerfDebug';

import reader from 'store/reader';
import routes from 'store/routes';

const rootReducer = combineReducers({
  reader,
  routes
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
