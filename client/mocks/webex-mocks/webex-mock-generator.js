const fs = require('fs');
const faker = require('faker');
const generateMeetingData = require('./meetingData.js');

const MOCK_FILE_PATH = 'mocks/webex-mocks/webex-mock.json';
const FORCE_RECREATE_MOCK = process.argv.includes('--force');

const generateConferenceLinks = () => {
  const webexLinks = [];

  for (let id = 1; id <= 10; id++) {
    const startDate = new Date('2021-01-01T00:00:00Z');
    const endDate = new Date('2023-01-01T00:00:00Z');

    const randomStartDate = faker.date.between(startDate, endDate);
    const randomEndDate = new Date(randomStartDate.getTime());

    randomEndDate.setHours(randomEndDate.getHours() + 1);

    const startTime = randomStartDate.toISOString().replace('Z', '');
    const endTime = randomEndDate.toISOString().replace('Z', '');

    const subject = faker.lorem.words();

    const updatedValues = {
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

const conferencesArePopulated = () => {
  const fileContents = JSON.parse(fs.readFileSync(MOCK_FILE_PATH, 'utf-8'));

  return fileContents && fileContents.conferenceLinks.length > 0;
};

if (fs.existsSync(MOCK_FILE_PATH)) {
  if (FORCE_RECREATE_MOCK || !conferencesArePopulated()) {
    // eslint-disable-next-line no-console
    console.log('Resetting webex-mock.json');

    fs.unlinkSync(MOCK_FILE_PATH);
  } else {
    // eslint-disable-next-line no-console
    console.log('webex-mock.json already exists. Skipping creation and exiting.');

    return;
  }
}

// Generate the data
const data = {
  conferenceLinks: generateConferenceLinks(),
  // ... other data models
};

// Check if the script is being run directly
if (require.main === module) {
  fs.writeFileSync(
    MOCK_FILE_PATH,
    JSON.stringify(data, null, 2)
  );
  // eslint-disable-next-line no-console
  console.log('Generated new data in webex-mock.json');
}
