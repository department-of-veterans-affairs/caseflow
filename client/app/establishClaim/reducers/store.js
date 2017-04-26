import { applyMiddleware, createStore, combineReducers } from 'redux';
import logger from 'redux-logger';
import thunk from 'redux-thunk';
import specialIssuesReducer, { getSpecialIssuesInitialState } from './specialIssues';
import establishClaimReducer, { getEstablishClaimInitialState } from './index';
import establishClaimFormReducer,
  { getEstablishClaimFormInitialState } from './establishClaimForm';
import ConfigUtil from '../../util/ConfigUtil';

export const createEstablishClaimStore = (props) => {
  let middleware = [thunk];


  // Avoid all the log spam when running the tests
  if (!ConfigUtil.test()) {
    middleware.push(logger);
  }

  return createStore(
    combineReducers({
      specialIssues: specialIssuesReducer,
      establishClaimForm: establishClaimFormReducer,
      // Reducer with general/common state
      establishClaim: establishClaimReducer
    }),
    {
      specialIssues: getSpecialIssuesInitialState(props),
      establishClaimForm: getEstablishClaimFormInitialState(props),
      establishClaim: getEstablishClaimInitialState()
    },
    applyMiddleware(...middleware)
  );
};
