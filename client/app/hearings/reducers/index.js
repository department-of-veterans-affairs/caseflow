import { combineReducers } from 'redux';
import { timeFunction } from '../../util/PerfDebug';
import commonComponentsReducer from '../../components/common/reducers';
import caseListReducer from '../../queue/CaseList/CaseListReducer';
import { workQueueReducer } from '../../queue/reducers';
import hearingWorksheetReducer from './hearingWorksheetReducer';
import hearingScheduleReducer from './hearingScheduleReducer';
import dailyDocketReducer from './dailyDocketReducer';
import uiReducer from '../../queue/uiReducer/uiReducer';

const combinedReducer = combineReducers({
  hearingWorksheet: hearingWorksheetReducer,
  hearingSchedule: hearingScheduleReducer,
  dailyDocket: dailyDocketReducer,
  ui: uiReducer,
  caseList: caseListReducer,
  queue: workQueueReducer,
  components: commonComponentsReducer
});

export default timeFunction(
  combinedReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
