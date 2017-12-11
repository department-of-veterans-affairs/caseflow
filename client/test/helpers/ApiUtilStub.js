import sinon from 'sinon';
import ApiUtil from '../../app/util/ApiUtil';

export default {
  apiPatch: null,
  apiPost: null,
  apiGet: null,
  apiDelete: null,
  apiPut: null,

  beforeEach() {
    const makeFakePromise = () => {
      // The Reader tests manually populate data, but they also allowing the calling
      // code to make API requests. In the past, those requests have all failed,
      // and we just ignored the errors. Giving an empty response here will allow
      // the API response handlers to not crash.

      return Promise.resolve({ text: '{}' });
    };

    this.apiPatch = sinon.stub(ApiUtil, 'patch').returns(makeFakePromise());
    this.apiGet = sinon.stub(ApiUtil, 'get').returns(makeFakePromise());
    this.apiPost = sinon.stub(ApiUtil, 'post').returns(makeFakePromise());
    this.apiDelete = sinon.stub(ApiUtil, 'delete').returns(makeFakePromise());
    this.apiPut = sinon.stub(ApiUtil, 'put').returns(makeFakePromise());
  },

  afterEach() {
    ApiUtil.patch.restore();
    ApiUtil.post.restore();
    ApiUtil.get.restore();
    ApiUtil.delete.restore();
    ApiUtil.put.restore();
  }
};
