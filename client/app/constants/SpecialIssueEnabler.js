import { SPECIAL_ISSUES, NEW_SPECIAL_ISSUES } from './SpecialIssues';

// NEW_SPECIAL_ISSUES was added to SpecialIssues.jsx in 2020-Spring. Currently listed seperate from the main list in
// order to be locked to the FeatureToggle :special_issues_revamp here. As a part of removing the feature toggle,
// merge those arrays and refactor away this file.
export const enabledSpecialIssues = isFeatureToggled => isFeatureToggled ? SPECIAL_ISSUES.concat(NEW_SPECIAL_ISSUES) : SPECIAL_ISSUES
