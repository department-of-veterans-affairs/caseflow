import { applyMiddleware, createStore, combineReducers } from 'redux';
import logger from 'redux-logger';
import specialIssuesReducer, { getSpecialIssuesInitialState } from './specialIssues';
import ConfigUtil from '../../util/ConfigUtil';

export const createEstablishClaimStore = (props) => {
  let middleware = [];


  // Avoid all the log spam when running the tests
  if (!ConfigUtil.test()) {
    middleware.push(logger);
  }

  return createStore(
    combineReducers({ specialIssues: specialIssuesReducer }),
    { specialIssues: getSpecialIssuesInitialState(props) },
    applyMiddleware(...middleware)
  );
};
