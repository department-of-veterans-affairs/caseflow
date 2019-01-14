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
    return SPECIAL_ISSUES.filter((issue) => issue.section === 'about');
  },

  residenceSection() {
    return SPECIAL_ISSUES.filter((issue) => issue.section === 'residence');
  },

  benefitTypeSection () {
    return SPECIAL_ISSUES.filter((issue) => issue.section === 'benefitType');
  },

  issuesOnAppealSection () {
    return SPECIAL_ISSUES.filter((issue) => issue.section === 'issuesOnAppeal');
  },
  
  dicOrPensionSection () {
    return SPECIAL_ISSUES.filter((issue) => issue.section === 'dicOrPension');
  }

};

export default specialIssueFilters;
