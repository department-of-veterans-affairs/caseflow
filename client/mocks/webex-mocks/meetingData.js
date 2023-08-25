const faker = require('faker');

const generateMeetingData = (subject, startTime, endTime) => {
  const undefinedValue = undefined;

  if (
    startTime === undefinedValue &&
    endTime === undefinedValue &&
    subject === undefinedValue
  ) {
    startTime = faker.date.recent().toTimeString().
      split(' ')[0];
    endTime = faker.date.future().toTimeString().
      split(' ')[0];
    subject = faker.lorem.words();
  }

  return {
    id: faker.random.uuid(),
    jwt: {
      sub: subject,
      Nbf: startTime,
      Exp: endTime,
      flow: {
        id: faker.random.uuid(),
        data: [
          {
            uri: `${faker.internet.userName()}@intadmin.room.wbx2.com`,
          },
          {
            uri: `${faker.internet.userName()}@intadmin.room.wbx2.com`,
          },
        ],
      },
    },
    aud: faker.random.uuid(),
    numGuest: faker.random.number({ min: 1, max: 10 }),
    numHost: 1,
    provideShortUrls: faker.random.boolean(),
    verticalType: faker.company.catchPhrase(),
    loginUrlForHost: faker.random.boolean(),
    jweAlg: 'PBES2-HS512+A256KW',
    saltLength: faker.random.number({ min: 1, max: 16 }),
    iterations: faker.random.number({ min: 500, max: 2000 }),
    enc: 'A256GCM',
    jwsAlg: 'HS512',
  };
};

module.exports = generateMeetingData;
