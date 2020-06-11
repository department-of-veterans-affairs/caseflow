/* eslint-disable no-process-env */
module.exports = {
  moduleNameMapper: {
    '^app/(.*)$': '<rootDir>/app/$1',
    '^test/(.*)$': '<rootDir>/test/$1',
    '\\.(css|less|scss|sss|styl)$': '<rootDir>/node_modules/jest-css-modules'
  },
  setupFilesAfterEnv: ['./test/app/jestSetup.js'],
  transformIgnorePatterns: ['node_modules/(?!@department-of-veterans-affairs/caseflow-frontend-toolkit)'],
<<<<<<< HEAD
  collectCoverage: false,
  reporters: ['default', 'jest-junit'],
  // eslint-disable-next-line no-process-env
=======
  // eslint-disable-next-line no-undefined
  collectCoverage: process.env.TEST_REPORTER !== undefined,
  reporters: process.env.TEST_REPORTER ? [process.env.TEST_REPORTER] : ['default', 'jest-junit'],
>>>>>>> 14b822db13a7b7ccee503c98a27b9920ad6808eb
  coverageDirectory: process.env.JEST_DIR,
  collectCoverageFrom: ['app/**/*.{js,jsx}'],
  snapshotSerializers: ['enzyme-to-json/serializer']
};

/* eslint-enable no-process-env */
