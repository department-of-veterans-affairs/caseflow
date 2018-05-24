import _ from 'lodash';

export const getReaderLink = (appealVacolsId) => `/reader/appeal/${appealVacolsId}/documents`;

export const orderTheDocket = (docket) =>
  _.orderBy(docket, ['date', 'veteran_mi_formatted', 'appellant_mi_formatted'], ['asc', 'asc', 'asc']);
