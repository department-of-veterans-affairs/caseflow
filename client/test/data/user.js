export const anyUser = {
  name: 'John Smith',
  addressLine1: '123 Fake St.',
  addressState: 'DC',
  addressCity: 'Washington',
  addressZip: '20001'
};

export const userWithVirtualHearingsFeatureEnabled = {
  ...anyUser,
  userCanScheduleVirtualHearings: true
};

export const userWithConvertCentralHearingsEnabled = {
  ...anyUser,
  userCanConvertCentralHearings: true
};

export const userWithJudgeRole = {
  ...anyUser,
  userHasHearingPrepRole: true
};

export const userUseFullPageVideoToVirtual = {
  ...userWithVirtualHearingsFeatureEnabled,
  userUseFullPageVideoToVirtual: true
}
;
