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
  '& > p': {
    textTransform: 'uppercase',
    fontWeight: 'bold',
    fontSize: '15px',
    marginBottom: '12px',
    marginTop: '0',
    color: '#323a45',
    lineHeight: '1.3'
  },
  '& > div': { minHeight: '22px' }
});

export const TitleDetailsSubheaderSection = ({ title, children }) => (
  <div {...listItemStyling}>
    <p>{title}</p>
    <div>
      {children}
    </div>
  </div>
);

TitleDetailsSubheaderSection.propTypes = {
  children: PropTypes.node,
  title: PropTypes.string.isRequired
};
