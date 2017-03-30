import * as Constants from '../constants/constants';
import _ from 'lodash';

const establishClaim = function(state, action) {
  switch(action.type) {
      case Constants.CHANGE_SPECIAL_ISSUE:
      console.log('reducer line 6');
      let new_state = _.cloneDeep(state);
      new_state.specialIssues[action.payload.specialIssue] = action.payload.value;
      return new_state;
    default:
      return state;
  }
};

export default establishClaim;