import React from 'react';

import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';

const listStyling = css({
  verticalAlign: 'super',
  '::after': {
    content: ' ',
    clear: 'both',
    display: 'block'
  }
});

const listItemStyling = css({
  display: 'block',
  float: 'left',
  padding: '0.5rem 1.5rem 0.5rem 0',
  ':not(:last-child)': {
    '& > div': {
      borderRight: `1px solid ${COLORS.GREY_LIGHT}`
    },
    '& > *': {
      paddingRight: '1.5rem',
      minHeight: '22px'
    }
  },
  '& > h4': { textTransform: 'uppercase' }
});

const DetailsOverview = ({ columns }) => (
  <div {...listStyling}>
    {columns.map((col, i) => (
      <div key={i} {...listItemStyling}>
        <h4>{col.label}</h4>
        <div>
          {col.value}
        </div>
      </div>
    ))}
  </div>
);

export default DetailsOverview;
