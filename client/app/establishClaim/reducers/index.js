import * as Constants from '../constants/constants';

const establishClaim = function(state, action) {
  switch(action.type) {
    case Constants.CHANGE_SPECIAL_ISSUE:
      return Object.assign({}, state, {

          // let stateObject = {};
          //
          // stateObject[form] = { ...this.state[form] };
          // stateObject[form][field].value = value;
          // this.setState(stateObject);


      });
    default:
      return state;
  }
};

export default establishClaim;