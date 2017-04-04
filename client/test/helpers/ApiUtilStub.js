import sinon from 'sinon';
import ApiUtil from '../../app/util/ApiUtil';


export default {
  apiPatch: null,
  apiPost: null,
  apiGet: null,
  apiDelete: null,
  apiPut: null,

  beforeEach() {
    this.apiPatch = sinon.stub(ApiUtil, 'patch');
    this.apiPatch.resolves();

    this.apiGet = sinon.stub(ApiUtil, 'get');
    this.apiGet.resolves();

    this.apiPost = sinon.stub(ApiUtil, 'post');
    this.apiPost.resolves();

    this.apiDelete = sinon.stub(ApiUtil, 'delete');
    this.apiDelete.resolves();

    this.apiPut = sinon.stub(ApiUtil, 'put');
    this.apiPut.resolves();
  },

  afterEach() {
    ApiUtil.patch.restore();
    ApiUtil.post.restore();
    ApiUtil.get.restore();
    ApiUtil.delete.restore();
    ApiUtil.put.restore();
  }
};
