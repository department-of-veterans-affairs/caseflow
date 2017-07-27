import SPECIAL_ISSUES from '../../constants/SpecialIssues';
import { MODIFIER_OPTIONS } from '../constants';
import ROUTING_INFORMATION from '../../constants/Routing';

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
 * This function gets the set of unused modifiers.
 * This removes any modifiers that have already been
 * used in previous EPs.
 */
export const validModifiers = (endProducts) => {
  let modifiers = MODIFIER_OPTIONS;

  let modifierHash = endProducts.reduce((modifierObject, endProduct) => {
    modifierObject[endProduct.end_product_type_code] = true;

    return modifierObject;
  }, {});

  return modifiers.filter((modifier) => !modifierHash[modifier]);
};

const getRegionalOfficeString = (regionalOfficeKey, regionalOfficeCities) => {
  if (!regionalOfficeKey) {
    return null;
  }

  return `${regionalOfficeKey} - ${
      regionalOfficeCities[regionalOfficeKey].city}, ${
      regionalOfficeCities[regionalOfficeKey].state}`;
};

const getEmailFromConstant = (constant, regionalOfficeKey) => {
  return ROUTING_INFORMATION.codeToEmailMapper[constant[regionalOfficeKey]];
};

export const getSpecialIssuesRegionalOfficeCode = (specialIssuesRegionalOffice, regionalOfficeKey) => {
  if (specialIssuesRegionalOffice === 'PMC') {
    return ROUTING_INFORMATION.PMC[regionalOfficeKey];
  } else if (specialIssuesRegionalOffice === 'COWC') {
    return ROUTING_INFORMATION.COWC[regionalOfficeKey];
  } else if (specialIssuesRegionalOffice === 'education') {
    return ROUTING_INFORMATION.EDUCATION[regionalOfficeKey];
  }

  return specialIssuesRegionalOffice;

};

// This method returns a string version of the regional office code. So it takes "R081"
// and returns a string "RO81 - Philadelphia Pension Center, PA"
export const getSpecialIssuesRegionalOffice =
  (specialIssuesRegionalOffice, regionalOfficeKey, regionalOfficeCities) => {
    return getRegionalOfficeString(
      getSpecialIssuesRegionalOfficeCode(specialIssuesRegionalOffice, regionalOfficeKey),
      regionalOfficeCities
    );
  };

export const getSpecialIssuesEmail = (specialIssuesEmail, regionalOfficeKey) => {
  if (specialIssuesEmail === 'PMC') {
    return getEmailFromConstant(ROUTING_INFORMATION.PMC, regionalOfficeKey);
  } else if (specialIssuesEmail === 'COWC') {
    return getEmailFromConstant(ROUTING_INFORMATION.COWC, regionalOfficeKey);
  } else if (specialIssuesEmail === 'education') {
    return getEmailFromConstant(ROUTING_INFORMATION.EDUCATION, regionalOfficeKey);
  }

  return specialIssuesEmail;
};
