const faker = require('faker');

const generateMeetingData = (response) => {

  return {
    id: faker.random.uuid(),
    jwt: {
      sub: response.jwt.sub,
      Nbf: response.jwt.Nbf,
      Exp: response.jwt.Exp,
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
