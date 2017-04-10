import { applyMiddleware, createStore, combineReducers } from 'redux';
import logger from 'redux-logger';
import specialIssuesReducer, { getSpecialIssuesInitialState } from './specialIssues';
import establishClaimFormReducer, { getEstablishClaimFormInitialState } from './establishClaimForm';
import ConfigUtil from '../../util/ConfigUtil';

export const createEstablishClaimStore = (props) => {
  let middleware = [];


  // Avoid all the log spam when running the tests
  if (!ConfigUtil.test()) {
    middleware.push(logger);
  }

  return createStore(
    combineReducers({
      specialIssues: specialIssuesReducer,
      establishClaimForm: establishClaimFormReducer
    }),
    {
      specialIssues: getSpecialIssuesInitialState(props),
      establishClaimForm: getEstablishClaimFormInitialState(props)
    },
    applyMiddleware(...middleware)
  );
};
