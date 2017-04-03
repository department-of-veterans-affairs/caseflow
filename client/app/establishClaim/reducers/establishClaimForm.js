import { FULL_GRANT } from '../../containers/EstablishClaimPage/EstablishClaim';

const FULL_GRANT_MODIFIER_OPTIONS = [
  '172'
];

const PARTIAL_GRANT_MODIFIER_OPTIONS = [
  '170',
  '171',
  '175',
  '176',
  '177',
  '178',
  '179'
];

export default function(state = getEstablishClaimFormInitialState(), action) {
  switch(action.type) {
    case Constants.CHANGE_ESTABLISH_CLAIM_FIELD:
      let newState = Object.assign({}, state);
      newState[action.payload.field] = action.payload.value;
      return newState;
    default:
      return state;
  }
}

/*
 * This function gets the set of unused modifiers. For a full grant, only one
 * modifier, 172, is valid. For partial grants, 170, 171, 175, 176, 177, 178, 179
 * are all potentially valid. This removes any modifiers that have already been
 * used in previous EPs.
 */
export function validModifiers(endProducts, decisionType) {
  let modifiers = [];

  if (decisionType === FULL_GRANT) {
    modifiers = FULL_GRANT_MODIFIER_OPTIONS;
  } else {
    modifiers = PARTIAL_GRANT_MODIFIER_OPTIONS;
  }

  let modifierHash = endProducts.reduce((modifierObject, endProduct) => {
    modifierObject[endProduct.end_product_type_code] = true;

    return modifierObject;
  }, {});

  return modifiers.filter((modifier) => !modifierHash[modifier]);
}

export function getEstablishClaimFormInitialState(props = {}) {
  return {
    stationOfJurisdiction: null,
    endProductModifier: validModifiers[0],
    gulfWarRegistry: false,
    suppressAcknowledgementLetter: false
  };
}
