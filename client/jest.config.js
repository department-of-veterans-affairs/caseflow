module.exports = {
  moduleNameMapper: {
    '^app/(.*)$': '<rootDir>/app/$1',
    '^test/(.*)$': '<rootDir>/test/$1'
  },
  setupFilesAfterEnv: ['./test/app/jestSetup.js'],
  transformIgnorePatterns: ['node_modules/(?!@department-of-veterans-affairs/caseflow-frontend-toolkit)'],
  collectCoverage: true,
  // eslint-disable-next-line no-process-env
  reporters: process.env.TEST_REPORTER ? [process.env.TEST_REPORTER] : ['default', 'jest-junit'],
  // eslint-disable-next-line no-process-env
  coverageDirectory: process.env.JEST_DIR,
  collectCoverageFrom: ['app/**/*.{js,jsx}'],
  snapshotSerializers: ['enzyme-to-json/serializer']
};
