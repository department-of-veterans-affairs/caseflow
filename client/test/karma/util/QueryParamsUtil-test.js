import { expect } from 'chai';
import { getQueryParams } from '../../../app/util/QueryParamsUtil';

describe('getQueryParams', () => {

  const oneParam = '?category=case_summary';

  it('handles one param', () => {
    expect(getQueryParams(oneParam)).to.eql({ category: 'case_summary' });
  });

  const multipleParams = '?category=case_summary&search=form_9';

  it('handles multiple params', () => {
    expect(getQueryParams(multipleParams)).to.eql({ category: 'case_summary',
      search: 'form_9' });
  });

  const noParams = '';

  it('handles no params', () => {
    expect(getQueryParams(noParams)).to.eql({});
  });

  const missingKeyAndValue = '?category=case_summary&&search=form_9';

  it('handles a missing key and value', () => {
    expect(getQueryParams(missingKeyAndValue)).to.eql({ category: 'case_summary',
      search: 'form_9' });
  });

  const missingValue = '?category=&search=form_9';

  it('handles a missing value', () => {
    expect(getQueryParams(missingValue)).to.eql({ category: '',
      search: 'form_9' });
  });

  const missingKey = '?=case_summary&search=form_9';

  it('handles a missing key', () => {
    expect(getQueryParams(missingKey)).to.eql({ search: 'form_9' });
  });
});
