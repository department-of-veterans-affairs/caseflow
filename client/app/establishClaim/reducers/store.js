import { applyMiddleware, createStore, combineReducers } from 'redux';
import logger from 'redux-logger';
import specialIssuesReducer, { getSpecialIssuesInitialState } from './specialIssues';

export const createEstablishClaimStore = (props) => {
  // Logger with default options

  return createStore(
    combineReducers({ specialIssues: specialIssuesReducer }),
    { specialIssues: getSpecialIssuesInitialState(props) },
    applyMiddleware(logger)
  );
};
