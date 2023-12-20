import { getQueryParams } from '../../../app/util/QueryParamsUtil';

describe('getQueryParams', () => {

  const oneParam = '?category=case_summary';

  it('handles one param', () => {
    expect(getQueryParams(oneParam)).toEqual({ category: 'case_summary' });
  });

  const multipleParams = '?category=case_summary&search=form_9';

  it('handles multiple params', () => {
    expect(getQueryParams(multipleParams)).toEqual({ category: 'case_summary',
      search: 'form_9' });
  });

  const noParams = '';

  it('handles no params', () => {
    expect(getQueryParams(noParams)).toEqual({});
  });

  const missingKeyAndValue = '?category=case_summary&&search=form_9';

  it('handles a missing key and value', () => {
    expect(getQueryParams(missingKeyAndValue)).toEqual({ category: 'case_summary',
      search: 'form_9' });
  });

  const missingValue = '?category=&search=form_9';

  it('handles a missing value', () => {
    expect(getQueryParams(missingValue)).toEqual({ category: '',
      search: 'form_9' });
  });

  const missingKey = '?=case_summary&search=form_9';

  it('handles a missing key', () => {
    expect(getQueryParams(missingKey)).toEqual({ search: 'form_9' });
  });
});
