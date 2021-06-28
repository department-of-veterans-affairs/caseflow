import faker from 'faker';

export const anyUser = {
  name: 'John Smith',
  addressLine1: '123 Fake St.',
  addressState: 'DC',
  addressCity: 'Washington',
  addressZip: '20001',
};

export const userWithVirtualHearingsFeatureEnabled = {
  ...anyUser,
  userCanScheduleVirtualHearings: true,
};

export const userWithConvertCentralHearingsEnabled = {
  ...anyUser,
  userCanConvertCentralHearings: true,
};

export const userWithJudgeRole = {
  ...anyUser,
  userHasHearingPrepRole: true,
};

export const vsoUser = {
  ...anyUser,
  userCanVsoHearingSchedule: true,
  userCanAssignHearingSchedule: false
}

export const userUseFullPageVideoToVirtual = {
  ...userWithVirtualHearingsFeatureEnabled,
  userUseFullPageVideoToVirtual: true,
};

const attyTemplate = ({ id }) => {
  const name = faker.name.findName();

  return {
    id,
    display_name: name,
    css_id: faker.internet.userName(name),
  };
};

export const generateAttorneys = (number) => {
  const result = [];

  for (let i = 1; i < number + 1; i++) {
    result.push(attyTemplate(i));
  }

  return result;
};
