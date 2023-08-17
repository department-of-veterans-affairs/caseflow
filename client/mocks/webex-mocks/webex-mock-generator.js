const fs = require("fs");
const faker = require("faker");

const generateConferenceLinks = () => {
  let users = [];

  for (let id = 1; id <= 10; id++) {
    users.push({
      id: id,
      name: faker.name.firstName(),
      email: faker.internet.email(),
      address: faker.address.streetAddress(),
      // ... other fields
    });
  }

  return users;
};

// Generate the data
const data = {
  conferenceLinks: generateConferenceLinks(),
  // ... other data models
};

// Check if the script is being run directly
if (require.main === module) {
  fs.writeFileSync("mocks/webex-mocks/webex-mock.json", JSON.stringify(data, null, 2));
  console.log("Generated new data in webex-mock.json");
}

