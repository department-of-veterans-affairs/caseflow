import { SPECIAL_ISSUES, AMA_SPECIAL_ISSUES } from './SpecialIssues';

export const enabledSpecialIssues = (wantsAmaIssues) => wantsAmaIssues ? SPECIAL_ISSUES.concat(AMA_SPECIAL_ISSUES) : SPECIAL_ISSUES;
