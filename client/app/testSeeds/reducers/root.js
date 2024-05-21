import { timeFunction } from '../../util/PerfDebug';
import { combineReducers } from 'redux';
import seedsReducer from './seeds/seedsReducer';

const rootReducer = combineReducers({
  testSeeds: seedsReducer
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
