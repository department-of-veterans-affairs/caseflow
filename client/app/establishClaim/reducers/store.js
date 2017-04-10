import { applyMiddleware, createStore, combineReducers } from 'redux';
import logger from 'redux-logger';
import specialIssuesReducer, { getSpecialIssuesInitialState } from './specialIssues';

export const createEstablishClaimStore = (props) => {
  let middleware = [];


  // Avoid all the log spam when running the tests
  if (process.env.NODE_ENV !== 'test') {
    middleware.push(logger);
  }

  return createStore(
    combineReducers({ specialIssues: specialIssuesReducer }),
    { specialIssues: getSpecialIssuesInitialState(props) },
    applyMiddleware(...middleware)
  );
};
