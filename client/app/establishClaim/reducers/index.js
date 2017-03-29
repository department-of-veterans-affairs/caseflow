import * as Constants from '../constants/constants';

const establishClaim = function(state, action) {
  switch(action.type) {
    case Constants.CHANGE_SPECIAL_ISSUE:
      let new_state = Object.assign({}, state);
      new_state.specialIssues[action.payload.specialIssue] = action.payload.value;
      return new_state;
    default:
      return state;
  }
};

export default establishClaim;