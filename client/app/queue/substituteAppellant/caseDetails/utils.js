// Function for determining if appellant substution functionality should be enabled
// Examines appeal data, feature toggles, and info re current user
export const shouldSupportSubstituteAppellant = ({
  appeal,
  currentUserOnClerkOfTheBoard,
  featureToggles,
  hasSubstitution,
  userIsCobAdmin,
}) => {
  const decisionHasDismissedDeathDisposition = (decisionIssue) =>
    decisionIssue.disposition === 'dismissed_death';

  return (
    !appeal.isLegacyAppeal &&
    appeal.veteranDateOfDeath &&
      currentUserOnClerkOfTheBoard &&
      !appeal.appellantIsNotVeteran &&
      featureToggles.recognized_granted_substitution_after_dd &&
      appeal.caseType === 'Original' &&
      // Substitute appellants for hearings require separate feature toggle
      (appeal.docketName !== 'hearing' ||
        featureToggles.hearings_substitution_death_dismissal) &&
      // For now, only allow a single substitution from a given appeal
      !hasSubstitution &&
      // Only admins can perform sub on cases w/o all issues having disposition `dismissed_death`
      (userIsCobAdmin ||
        appeal.decisionIssues.some(decisionHasDismissedDeathDisposition))
  );
};

