import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';

import { COLORS } from '../constants/AppConstants';

const listItemStyling = css({
  display: 'inline-block',
  padding: '0.5rem 1.5rem 0.5rem 0',
  ':not(:last-child)': {
    '& > div': {
      borderRight: `1px solid ${COLORS.GREY_LIGHT}`
    },
    '& > *': {
      paddingRight: '1.5rem'
    }
  },
  '& > h4': { textTransform: 'uppercase' },
  '& > div': { minHeight: '22px' }
});

export const TitleDetailsSubheaderSection = ({ title, children }) => (
  <div {...listItemStyling}>
    <h4>{title}</h4>
    <div>
      {children}
    </div>
  </div>
);

TitleDetailsSubheaderSection.propTypes = {
  children: PropTypes.node,
  title: PropTypes.string.isRequired
};
