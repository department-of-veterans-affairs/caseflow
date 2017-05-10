import SPECIAL_ISSUES from './SpecialIssues';

const specialIssueFilters = {

  unhandledSpecialIssues() {
    return SPECIAL_ISSUES.filter((issue) => {
      return issue.unhandled;
    });
  },

  regionalSpecialIssues() {
    return SPECIAL_ISSUES.filter((issue) => {
      return issue.stationOfJurisdiction === 'regional';
    });
  },

  routedSpecialIssues() {
    return SPECIAL_ISSUES.filter((issue) => {
      return issue.stationOfJurisdiction &&
        issue.stationOfJurisdiction !== 'regional';
    });
  },

  routedOrRegionalSpecialIssues() {
    return SPECIAL_ISSUES.filter((issue) => {
      return issue.stationOfJurisdiction;
    });
  }
};

export default specialIssueFilters;
