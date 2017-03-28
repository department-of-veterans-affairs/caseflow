import * as Constants from '../constants/constants';

const establishClaim = function(state, action) {
  switch(action.type) {
    case Constants.CHANGE_SPECIAL_ISSUE:
      return Object.assign({}, state, {

      });
    default:
      return state;
  }
};

export default establishClaim;