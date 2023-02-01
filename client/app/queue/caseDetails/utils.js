export const shouldShowVsoVisibilityAlert = ({ featureToggles, userIsVsoEmployee }) => {
  // eslint-disable-next-line camelcase
  return userIsVsoEmployee && featureToggles?.restrict_poa_visibility;
};

export const isAppealNewCavcDecisionType = (appeal) => {
  return appeal.decisionIssues?.some((decisionIssue) =>
    decisionIssue.disposition === 'other_dismissal' ||
    decisionIssue.disposition === 'affirmed' ||
    decisionIssue.disposition === 'settlement');
};
