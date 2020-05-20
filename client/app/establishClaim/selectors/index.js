import { createSelector } from 'reselect';
import specialIssueFilters from '../../constants/SpecialIssueFilters';
import { ARC_STATION_OF_JURISDICTION } from '../constants';
import requiredValidator from '../../util/validators/RequiredValidator';

const getSpecialIssues = (specialIssues) => specialIssues;
const getStationKey = (_, stationKey) => stationKey;

export const getStationOfJurisdiction = createSelector(
  [getSpecialIssues, getStationKey],
  (specialIssues, stationKey, special_issues_revamp) => {
    let station = ARC_STATION_OF_JURISDICTION;

    // Go through the special issues, and for any regional issues, set SOJ to RO
    specialIssueFilters(special_issues_revamp).regionalSpecialIssues().forEach((issue) => {
      if (specialIssues[issue.specialIssue]) {
        station = stationKey;
      }
    });

    // Go through all the special issues, this time looking for routed issues
    specialIssueFilters(special_issues_revamp).routedSpecialIssues().forEach((issue) => {
      if (specialIssues[issue.specialIssue]) {
        station = issue.stationOfJurisdiction.key;
      }
    });

    return station;
  }
);

const getIsValdating = (state) => state.isValidating;
const getCancelFeedback = (state) => state.cancelFeedback;
const getValidator = () => requiredValidator('Please enter an explanation');

export const getCancelFeedbackErrorMessage = createSelector(
  [getIsValdating, getCancelFeedback, getValidator],
  (isValidating, cancelFeedback, validator) => {
    if (isValidating) {
      return validator(cancelFeedback);
    }
  }
);
