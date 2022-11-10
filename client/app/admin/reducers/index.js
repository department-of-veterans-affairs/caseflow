import { combineReducers } from 'redux';
import { timeFunction } from '../../util/PerfDebug';
import commonComponentsReducer from '../../components/common/reducers';
import { featureToggleReducer } from './featureToggle';
import { ACTIONS } from '../constants';

const extractInitialState = {};

export const extractReducer = (state = extractInitialState, action) => {
  switch (action.type) {
  case ACTIONS.STARTED_VETERAN_EXTRACT:
    return { ...state };
  case ACTIONS.POST_VETERAN_EXTRACT:
    return {
      ...state,
      manualExtractionStatus: action.payload.status,
      manualExtractionSuccess: action.payload.success,
    };
  case ACTIONS.FAILED_VETERAN_EXTRACT:
    return {
      ...state,
      manualExtractionStatus: action.payload.status,
      manualExtractionSuccess: false,
    };
  default:
    return state;
  }
};

const combinedReducer = combineReducers({
  featureToggle: featureToggleReducer,
  components: commonComponentsReducer,
  extractReducer
});

export default timeFunction(
  combinedReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
