import { combineReducers } from 'redux';
import { timeFunction } from '../../util/PerfDebug';
import commonComponentsReducer from '../../components/common/reducers';
import { featureToggleReducer } from './featureToggle';

const combinedReducer = combineReducers({
  featureToggle: featureToggleReducer,
  components: commonComponentsReducer
});

export default timeFunction(
  combinedReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
