import { timeFunction } from '../../util/PerfDebug';
import { combineReducers } from 'redux';
import leversReducer from './levers/leversReducer';

const rootReducer = combineReducers({
  caseDistributionLevers: leversReducer
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
