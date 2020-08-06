
/* eslint-disable no-process-env */
module.exports = async () => {
  // Standardize the timezone in which tests are run
  process.env.TZ = 'America/New_York';
};
/* eslint-enable no-process-env */
