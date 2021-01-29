import { css } from 'glamor';
import React from 'react';

import { boldText } from './constants';

export const detailListStyling = css({
  paddingLeft: 0,
  listStyle: 'none',
  marginBottom: '3rem'
});

export const getDetailField = ({ label, value }) => () => (
  <><span {...boldText}>{label}:</span>{' '}{value}</>
);
