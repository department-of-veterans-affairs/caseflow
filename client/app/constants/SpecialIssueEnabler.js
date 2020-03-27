import { SPECIAL_ISSUES, NEW_SPECIAL_ISSUES } from './SpecialIssues';

export const enabledSpecialIssues = isFeatureToggled => isEnabled ? SPECIAL_ISSUES.concat(NEW_SPECIAL_ISSUES) : SPECIAL_ISSUES
