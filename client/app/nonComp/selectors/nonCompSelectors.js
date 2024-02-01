export const selectBusinessLineUrl = (state) => state.nonComp?.businessLineUrl;

export const selectIsVhaBusinessLine = (state) => {
  const businessLineUrl = selectBusinessLineUrl(state);

  return businessLineUrl === 'vha';
};

export const selectBaseTasksUrl = (state) => state.nonComp?.baseTasksUrl;

export const selectPoaRefreshButton = (state) => {
  // Feature toggles should really be their own redux slice that could be imported everywhere
  // eslint-disable-next-line camelcase
  return state?.ui?.featureToggles?.poa_button_refresh ?? state?.nonComp?.featureToggles?.poa_button_refresh;
};
