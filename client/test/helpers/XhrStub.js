import sinon from 'sinon';

export default {
  beforeEach() {
    this.xhr = sinon.useFakeXMLHttpRequest();

    this.xhr.onCreate = function (xhr) {
      console.log('request url: ', xhr.url);
    };
  },

  afterEach() {
    this.xhr.restore();
  }
};
