import * as Constants from '../constants';
import ReducerUtil from '../../util/ReducerUtil';
import { validModifiers } from '../util';
import update from 'immutability-helper';

export const getEstablishClaimFormInitialState = (props = {}) => {
  let initialModifier;

  if (props.task) {
    initialModifier = validModifiers(props.task.appeal.pending_eps, props.task.appeal.dispatch_decision_type)[0];
  }

  return {
    stationOfJurisdiction: null,
    endProductModifier: initialModifier,
    gulfWarRegistry: false,
    suppressAcknowledgementLetter: true
  };
};

export const establishClaimFormReducer = (state = getEstablishClaimFormInitialState(), action) => {
  switch (action.type) {
  case Constants.CHANGE_ESTABLISH_CLAIM_FIELD:
    return ReducerUtil.changeFieldValue(state, action);
  case Constants.INCREMENT_MODIFIER_ON_DUPLICATE_EP_ERROR:
    return update(state, { endProductModifier: { $set: action.payload.value } });
  default:
    return state;
  }
};

export default establishClaimFormReducer;
