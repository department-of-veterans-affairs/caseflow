import * as Constants from '../constants';
import ReducerUtil from '../../util/ReducerUtil';
import { validModifiers } from '../util';

export const getEstablishClaimFormInitialState = (props) => {
  let initialModifier;

  if (props) {
    initialModifier = validModifiers(
      props.task.appeal.pending_eps,
      props.task.appeal.decision_type
    )[0];
  }

  return {
    stationOfJurisdiction: null,
    endProductModifier: initialModifier,
    gulfWarRegistry: false,
    suppressAcknowledgementLetter: false
  };
};

export const establishClaimFormReducer =
  (state = getEstablishClaimFormInitialState(), action) => {
    switch (action.type) {
    case Constants.CHANGE_ESTABLISH_CLAIM_FIELD:
      return ReducerUtil.changeFieldValue(state, action);
    default:
      return state;
    }
  };

export default establishClaimFormReducer;
