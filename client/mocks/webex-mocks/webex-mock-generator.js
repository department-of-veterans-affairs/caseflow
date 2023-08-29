const fs = require('fs');
const faker = require('faker');
const generateMeetingData = require('./meetingData.js');

const generateConferenceLinks = () => {
  let webexLinks = [];

  for (let id = 1; id <= 10; id++) {
    const startDate = new Date('2021-01-01T00:00:00Z');
    const endDate = new Date('2023-01-01T00:00:00Z');

    const randomStartDate = faker.date.between(startDate, endDate);
    const randomEndDate = new Date(randomStartDate.getTime());

    randomEndDate.setHours(randomEndDate.getHours() + 1);

    let startTime = randomStartDate.toISOString().replace('Z', '');
    let endTime = randomEndDate.toISOString().replace('Z', '');

    let subject = faker.lorem.words();

    let updatedValues = {
      jwt: {
        sub: subject,
        Nbf: startTime,
        Exp: endTime
      }
    };

    webexLinks.push(generateMeetingData(updatedValues));
  }

  return webexLinks;
};

// Generate the data
const data = {
  conferenceLinks: generateConferenceLinks(),
  // ... other data models
};

// Check if the script is being run directly
if (require.main === module) {
  fs.writeFileSync(
    'mocks/webex-mocks/webex-mock.json',
    JSON.stringify(data, null, 2)
  );
  // eslint-disable-next-line no-console
  console.log("Generated new data in webex-mock.json");
}
