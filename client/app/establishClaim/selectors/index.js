import { createSelector } from 'reselect'
import specialIssueFilters from '../../constants/SpecialIssueFilters';

const getSpecialIssues = (specialIssues) => specialIssues;
const getStationKey = (_, stationKey) => stationKey;

export const getStationOfJurisdiction = createSelector(
  [getSpecialIssues, getStationKey],
  (specialIssues, stationKey) => {
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
    return station;
  }
)
