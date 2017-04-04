import specialIssueFilters from '../../constants/SpecialIssueFilters';
import * as Constants from '../constants/constants';

/*
* This function takes the special issues from the review page and sets the station
* of jurisdiction in the form page. Special issues that all go to the same spot are
* defined in the constant ROUTING_SPECIAL_ISSUES. Special issues that go back to the
* regional office are defined in REGIONAL_OFFICE_SPECIAL_ISSUES.
*/
export function setStationOfJurisdictionAction(specialIssues, stationKey) {
  let station = '397';

  // Go through the special issues, and for any regional issues, set SOJ to RO
  specialIssueFilters.regionalSpecialIssues().forEach((issue) => {
    if (specialIssues[issue.specialIssue]) {
      station = stationKey;
    }
  });

  // Go through all the special issues, this time looking for routed issues
  specialIssueFilters.routedSpecialIssues().forEach((issue) => {
    if (specialIssues[issue.specialIssue]) {
      station = issue.stationOfJurisdiction.key;
    }
  });

  return {
    type: Constants.CHANGE_ESTABLISH_CLAIM_FIELD,
    payload: {
      field: 'stationOfJurisdiction',
      value: station
    }
  }
}
