import { enabledSpecialIssues } from './SpecialIssueEnabler.js';

const specialIssueFilters = (isFeatureToggled) => ({

  unhandledSpecialIssues() {
    return enabledSpecialIssues(isFeatureToggled).filter((issue) => {
      return issue.unhandled;
    });
  },

  regionalSpecialIssues() {
    return enabledSpecialIssues(isFeatureToggled).filter((issue) => {
      return issue.stationOfJurisdiction === 'regional';
    });
  },

  routedSpecialIssues() {
    return enabledSpecialIssues(isFeatureToggled).filter((issue) => {
      return issue.stationOfJurisdiction &&
        issue.stationOfJurisdiction !== 'regional';
    });
  },

  routedOrRegionalSpecialIssues() {
    return enabledSpecialIssues(isFeatureToggled).filter((issue) => {
      return issue.stationOfJurisdiction;
    });
  },

  noneSection() {
    return enabledSpecialIssues(isFeatureToggled).filter((issue) => issue.queueSection === 'noSpecialIssues');
  },

  aboutSection() {
    return enabledSpecialIssues(isFeatureToggled).filter((issue) => issue.queueSection === 'about');
  },

  residenceSection() {
    return enabledSpecialIssues(isFeatureToggled).filter((issue) => issue.queueSection === 'residence');
  },

  benefitTypeSection () {
    return enabledSpecialIssues(isFeatureToggled).filter((issue) => issue.queueSection === 'benefitType');
  },

  issuesOnAppealSection () {
    return enabledSpecialIssues(isFeatureToggled).filter((issue) => issue.queueSection === 'issuesOnAppeal');
  },

  dicOrPensionSection () {
    return enabledSpecialIssues(isFeatureToggled).filter((issue) => issue.queueSection === 'dicOrPension');
  },

  amaIssuesOnAppealSection () {
    return enabledSpecialIssues(isFeatureToggled).filter((issue) => issue.isAmaRelevant && issue.queueSection === 'issuesOnAppeal');
  }
});

export default specialIssueFilters;
