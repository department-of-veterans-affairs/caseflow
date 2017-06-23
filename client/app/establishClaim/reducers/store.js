import { combineReducers } from 'redux';
import specialIssuesReducer, { getSpecialIssuesInitialState } from './specialIssues';
import establishClaimReducer, { getEstablishClaimInitialState } from './index';
import establishClaimFormReducer,
  { getEstablishClaimFormInitialState } from './establishClaimForm';
import configureStore from '../../util/ConfigureStore';

export const createEstablishClaimStore = (props) => {
  const reducers = combineReducers({
    specialIssues: specialIssuesReducer,
    establishClaimForm: establishClaimFormReducer,
    // Reducer with general/common state
    establishClaim: establishClaimReducer
  });

  const initialState = {
    specialIssues: getSpecialIssuesInitialState(props),
    establishClaimForm: getEstablishClaimFormInitialState(props),
    establishClaim: getEstablishClaimInitialState()
  };

  return configureStore({ reducers,
    initialState });
};
