import { expect } from 'chai';
import ApiUtil from '../../app/util/ApiUtil';

describe('ApiUtil', () => {
  context('.headers', () => {
    it('returns default headers', () => {
      let headers = ApiUtil.headers();
      expect(headers['Accept']).to.eq('application/json')
      expect(headers['Content-Type']).to.eq('application/json')
      expect(Object.keys(headers)).to.include('X-CSRF-Token')
    });
  });

  context('.patch', () => {
    it('returns Request object', () => {
      let req = ApiUtil.patch('/foo');

      expect(req.url).to.eq('/foo')
      expect(req.header['X-HTTP-METHOD-OVERRIDE']).to.eq('patch')
      expect(req.header['Cache-Control']).to.include('no-cache')
    });
  });
});
