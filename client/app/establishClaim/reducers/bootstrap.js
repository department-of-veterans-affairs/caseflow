import { combineReducers } from 'redux';
import specialIssuesReducer, { getSpecialIssuesInitialState } from './specialIssues';
import establishClaimReducer, { getEstablishClaimInitialState } from './index';
import establishClaimFormReducer,
{ getEstablishClaimFormInitialState } from './establishClaimForm';

export default (props) => {
  return {
    reducer: combineReducers({
      specialIssues: specialIssuesReducer,
      establishClaimForm: establishClaimFormReducer,
      // Reducer with general/common state
      establishClaim: establishClaimReducer
    }),
    initialState: {
      specialIssues: getSpecialIssuesInitialState(props),
      establishClaimForm: getEstablishClaimFormInitialState(props),
      establishClaim: getEstablishClaimInitialState()
    }
  };
};
