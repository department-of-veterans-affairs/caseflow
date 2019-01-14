import SPECIAL_ISSUES from './SpecialIssues';
import QUEUE_SPECIAL_ISSUES from './QueueSpecialIssues';

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
    return QUEUE_SPECIAL_ISSUES.filter((issue) => issue.section === 'about');
  },

  residenceSection() {
    return QUEUE_SPECIAL_ISSUES.filter((issue) => issue.section === 'residence');
  },

  benefitTypeSection () {
    return QUEUE_SPECIAL_ISSUES.filter((issue) => issue.section === 'benefitType');
  },

  issuesOnAppealSection () {
    return QUEUE_SPECIAL_ISSUES.filter((issue) => issue.section === 'issuesOnAppeal');
  },

  dicOrPensionSection () {
    return QUEUE_SPECIAL_ISSUES.filter((issue) => issue.section === 'dicOrPension');
  }

};

export default specialIssueFilters;
