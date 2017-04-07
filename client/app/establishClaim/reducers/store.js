import { applyMiddleware, createStore, combineReducers } from 'redux';
import logger from 'redux-logger';
import specialIssuesReducer, { getSpecialIssuesInitialState } from './specialIssues';
import establishClaimFormReducer, { getEstablishClaimFormInitialState } from './establishClaimForm';

export const createEstablishClaimStore = (props) => {
  // Logger with default options

  return createStore(
    combineReducers({
      specialIssues: specialIssuesReducer,
      establishClaimForm: establishClaimFormReducer
    }),
    {
      specialIssues: getSpecialIssuesInitialState(props),
      establishClaimForm: getEstablishClaimFormInitialState(props)
    },
    applyMiddleware(logger)
  );
};
