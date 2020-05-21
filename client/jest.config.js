module.exports = {
  moduleNameMapper: {
    '^app/(.*)$': '<rootDir>/app/$1',
    '^test/(.*)$': '<rootDir>/test/$1'
  },
  setupFilesAfterEnv: ['./test/app/jestSetup.js'],
  transformIgnorePatterns: ['node_modules/(?!@department-of-veterans-affairs/caseflow-frontend-toolkit)'],
  collectCoverage: true,
  coverageReporters: ['lcov', 'jest-junit'],
  // eslint-disable-next-line no-process-env
  coverageDirectory: process.env.JEST_DIR,
  collectCoverageFrom: ['app/**/*.{js,jsx}']
};
