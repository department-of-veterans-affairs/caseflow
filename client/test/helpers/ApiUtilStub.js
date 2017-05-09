import sinon from 'sinon';
import ApiUtil from '../../app/util/ApiUtil';
import _ from 'lodash';

export default {
  apiPatch: null,
  apiPost: null,
  apiGet: null,
  apiDelete: null,
  apiPut: null,

  beforeEach() {
    const makeFakePromise = () => {
      const promise = Promise.resolve();

      promise.end = _.noop;
      
      return promise;
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
