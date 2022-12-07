import { combineReducers } from 'redux';
import { timeFunction } from '../../util/PerfDebug';
import commonComponentsReducer from '../../components/common/reducers';
import { ACTIONS } from '../constants';

const extractInitialState = { extractedResults: '', isLoading: false };

export const extractReducer = (state = extractInitialState, action) => {
  switch (action.type) {
  case ACTIONS.STARTED_VETERAN_EXTRACT:
    return { ...state,
      isLoading: true,
      extractedResults: '',
      emptyResultsMessage: '',
    };
  case ACTIONS.POST_VETERAN_EXTRACT:
    return {
      ...state,
      manualExtractionStatus: action.payload.status,
      manualExtractionSuccess: action.payload.success,
      extractedResults: action.payload.contents,
      emptyResultsMessage: action.payload.message,
      isLoading: false,
    };
  case ACTIONS.FAILED_VETERAN_EXTRACT:
    return {
      ...state,
      manualExtractionStatus: action.payload.status,
      manualExtractionSuccess: false,
      isLoading: false,
      error: action.payload.err
    };
  default:
    return { ...state, isLoading: false };
  }
};

const combinedReducer = combineReducers({
  components: commonComponentsReducer,
  extractReducer
});

export default timeFunction(
  combinedReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
