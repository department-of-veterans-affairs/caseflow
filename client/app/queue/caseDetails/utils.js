export const shouldShowVsoVisibilityAlert = ({ featureToggles, userIsVsoEmployee }) => {
  // eslint-disable-next-line camelcase
  return userIsVsoEmployee && featureToggles?.restrict_poa_visibility;
};
