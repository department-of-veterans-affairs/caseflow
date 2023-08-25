const fs = require('fs');
const generateMeetingData = require('./meetingData.js');

const generateConferenceLinks = () => {
  let webexLinks = [];

  for (let id = 1; id <= 10; id++) {
    webexLinks.push(generateMeetingData());
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
  fs.writeFileSync('mocks/webex-mocks/webex-mock.json', JSON.stringify(data, null, 2));
  // eslint-disable-next-line no-console
  console.log('Generated new data in webex-mock.json');
}

