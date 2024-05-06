import { timeFunction } from '../../util/PerfDebug';
import { combineReducers } from 'redux';

//TODO: Needs to Implement TestSeeds Reducer

const rootReducer = combineReducers({
  testSeedObjects: {}
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
