/* eslint-disable no-process-env */
module.exports = {
  moduleNameMapper: {
    '^app/(.*)$': '<rootDir>/app/$1',
    '^constants/(.*)$': '<rootDir>/constants/$1',
    '^test/(.*)$': '<rootDir>/test/$1',
    '^COPY': '<rootDir>/COPY',
    '\\.(css|less|scss|sss|styl)$': '<rootDir>/node_modules/jest-css-modules'
  },
  // Runs before the environment is configured
  globalSetup: './test/global-setup.js',
  setupFilesAfterEnv: ['./test/app/jestSetup.js'],
  transformIgnorePatterns: ['node_modules/(?!@department-of-veterans-affairs/caseflow-frontend-toolkit)'],
  // eslint-disable-next-line no-undefined
  collectCoverage: process.env.TEST_REPORTER !== undefined,
  reporters: process.env.TEST_REPORTER ? [process.env.TEST_REPORTER] : ['default', 'jest-junit'],
  coverageDirectory: process.env.JEST_DIR,
  collectCoverageFrom: ['app/**/*.{js,jsx}', '!**/*.stories.*'],
  testTimeout: 10000,
  snapshotSerializers: ['enzyme-to-json/serializer']
};

/* eslint-enable no-process-env */
