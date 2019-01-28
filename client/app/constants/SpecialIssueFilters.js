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
  },

  aboutSection() {
    return SPECIAL_ISSUES.filter((issue) => issue.queueSection === 'about');
  },

  residenceSection() {
    return SPECIAL_ISSUES.filter((issue) => issue.queueSection === 'residence');
  },

  benefitTypeSection () {
    return SPECIAL_ISSUES.filter((issue) => issue.queueSection === 'benefitType');
  },

  issuesOnAppealSection () {
    return SPECIAL_ISSUES.filter((issue) => issue.queueSection === 'issuesOnAppeal');
  },

  dicOrPensionSection () {
    return SPECIAL_ISSUES.filter((issue) => issue.queueSection === 'dicOrPension');
  }

};

export default specialIssueFilters;
