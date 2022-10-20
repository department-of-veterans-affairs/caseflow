import { combineReducers } from 'redux';
import { timeFunction } from '../../util/PerfDebug';
import commonComponentsReducer from '../../components/common/reducers';
// import caseListReducer from '../../queue/CaseList/CaseListReducer';
// import { workQueueReducer } from '../../queue/reducers';
import uiReducer from '../../queue/uiReducer/uiReducer';
import { featureToggleReducer } from './featureToggle';

const combinedReducer = combineReducers({
  featureToggle: featureToggleReducer,
  ui: uiReducer,
  // caseList: caseListReducer,
  // queue: workQueueReducer,
  components: commonComponentsReducer
});

export default timeFunction(
  combinedReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);