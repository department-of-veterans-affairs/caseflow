import _ from 'lodash';

export const getReaderLink = (appealVacolsId) => `/reader/appeal/${appealVacolsId}/documents`;

export const orderTheDocket = (docket) =>
  _.orderBy(docket, ['date', 'veteran_last_name', 'appellant_last_name'], ['asc', 'asc', 'asc']);
