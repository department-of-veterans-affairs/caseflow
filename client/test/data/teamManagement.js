import faker from 'faker';
import { createOrg } from './factory';

export const createJudgeTeam = (count = 1, values = {}) => {
  return createOrg(count, {
    type: 'JudgeTeam',
    name: faker.name.findName,
    ...values
  });
};

export const createDvcTeam = (count = 1, values = {}) => {
  return createOrg(count, {
    type: 'DvcTeam',
    name: faker.name.findName,
    ...values
  });
};

export const createVso = (count = 1, values = {}) => {
  // const name = faker.company.companyName;
  // const url = name.toLowerCase().encodeURI();
  const names = Array(count).fill().
    map(() => faker.company.companyName());
  const getName = () => names[0] ?? null;
  const getUrl = () => {
    const url = getName().toLowerCase().
      replace(/ /g, '-').
      replace(/[^\w-]+/g, '');

    // Mutate array to keep in sync
    names.splice(0, 1);

    return url;
  };

  return createOrg(count, {
    type: 'Vso',
    name: getName,
    url: getUrl,
    participant_id: () => faker.random.number({ min: 2000000, max: 3000000 }),
    ...values
  });
};
