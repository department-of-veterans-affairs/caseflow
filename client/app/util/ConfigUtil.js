/* eslint-disable no-process-env */

export default {
  environment: process.env.NODE_ENV,
  test() {
    return this.environment === 'test';
  }
};
