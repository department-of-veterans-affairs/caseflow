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

export const TitleDetailsSubheaderSection = ({ key, title, children }) => (
  <div key={key} {...listItemStyling}>
    <h4>{title}</h4>
    <div>
      {children}
    </div>
  </div>
);

TitleDetailsSubheaderSection.propTypes = {
  children: PropTypes.node.isRequired,
  key: PropTypes.oneOfType([
    PropTypes.number,
    PropTypes.string
  ]),
  title: PropTypes.string.isRequired
};
