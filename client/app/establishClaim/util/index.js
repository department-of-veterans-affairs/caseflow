import SPECIAL_ISSUES from '../../constants/SpecialIssues';
import {
  FULL_GRANT,
  FULL_GRANT_MODIFIER_OPTIONS,
  PARTIAL_GRANT_MODIFIER_OPTIONS
} from '../constants';

/*
 * This function returns a nicely formatted string for the station of jurisdiction
 * For example:
 *   '397' => '397 - ARC'
 *   '311' => '311 - Pittsburgh, PA'
 */
export const formattedStationOfJurisdiction = (
  stationOfJurisdiction,
  regionalOfficeKey,
  regionalOfficeCities
) => {
  let suffix;

  SPECIAL_ISSUES.forEach((issue) => {
    let issueKey = issue.stationOfJurisdiction && issue.stationOfJurisdiction.key;

    // If the assigned stationOfJurisdiction matches a routed special issue, use the
    // routed station's location
    if (issueKey && issueKey === stationOfJurisdiction) {
      suffix = issue.stationOfJurisdiction.location;
    }
  });

  // ARC is a special snowflake and doesn't show the state (DC)
  if (stationOfJurisdiction === '397') {
    suffix = 'ARC';
  }

  // If there is no routed special issue override, use the default city/state
  if (!suffix) {
    suffix = `${regionalOfficeCities[regionalOfficeKey].city}, ${
      regionalOfficeCities[regionalOfficeKey].state}`;
  }

  return `${stationOfJurisdiction} - ${suffix}`;
};

/*
 * This function gets the set of unused modifiers. For a full grant, only one
 * modifier, 172, is valid. For partial grants, 170, 171, 175, 176, 177, 178, 179
 * are all potentially valid. This removes any modifiers that have already been
 * used in previous EPs.
 */
export const validModifiers = (endProducts, decisionType) => {
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
};
