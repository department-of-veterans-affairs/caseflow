export const appealHasDeathDismissal = (appeal) => {
  return appeal.decisionIssues?.some((decisionIssue) =>
    decisionIssue.disposition === 'dismissed_death');
};

export const appealSupportsSubstitution = (appeal) => {
  return (
    // AMA-only
    !appeal.isLegacyAppeal &&
    // Currently only allow substitutions for veteran
    !appeal.appellantIsNotVeteran &&
    // Currently disallow substitutions for remands, etc
    appeal.caseType === 'Original'
  );
};

export const appealHasSubstitution = (appeal) => Boolean(appeal.substitutions?.length);

export const supportsSubstitutionPreDispatch = ({
  appeal,
  currentUserOnClerkOfTheBoard,
  featureToggles,
  userIsCobAdmin,
}) => {
  return (
    appealSupportsSubstitution(appeal) &&
    currentUserOnClerkOfTheBoard &&
    featureToggles?.listed_granted_substitution_before_dismissal && // eslint-disable-line camelcase
    // For now, only allow a single substitution from a given appeal
    !appealHasSubstitution(appeal) &&
    // below is needed to avoid showing multiple substitution buttons on post-dispatch appeals
    !appealHasDeathDismissal(appeal) &&
    // Only admins can perform sub on cases w/o FNOD status
    (userIsCobAdmin || appeal.veteranAppellantDeceased)
  );
};

// Function for determining if appellant substution functionality should be enabled
// Examines appeal data, feature toggles, and info re current user
export const supportsSubstitutionPostDispatch = ({
  appeal,
  currentUserOnClerkOfTheBoard,
  featureToggles,
  hasSubstitution,
  userIsCobAdmin,
}) => {
  return (
    appealSupportsSubstitution(appeal) &&
    currentUserOnClerkOfTheBoard &&
    // Substitute appellants for hearings require separate feature toggle
    (appeal.docketName !== 'hearing' ||
      featureToggles.hearings_substitution_death_dismissal) &&
    // For now, only allow a single substitution from a given appeal
    !hasSubstitution &&
    // Only admins can perform sub on cases w/o all issues having disposition `dismissed_death`
    (userIsCobAdmin || appealHasDeathDismissal(appeal))
  );
};

