import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';

import { COLORS } from '../constants/AppConstants';
import { TitleDetailsSubheaderSection } from './TitleDetailsSubheaderSection';

const listStyling = css({
  display: 'flex',
  flexWrap: 'wrap',
  padding: '1rem 0 1rem 0',
  '::after': {
    content: ' ',
    clear: 'both',
    display: 'block'
  }
});

const subHeaderContainerStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  display: 'block',
  padding: '0 0 0 2rem'
});

export const TitleDetailsSubheader = ({ columns, children, id }) => (
  <div {...subHeaderContainerStyling} id={id || ''}>
    <div {...listStyling}>
      {columns && columns.map((col, i) => (
        <TitleDetailsSubheaderSection key={i} title={col.label}>
          {col.value}
        </TitleDetailsSubheaderSection>
      ))}
      {children && children}
    </div>
  </div>
);

TitleDetailsSubheader.propTypes = {
  // A collection of child elements to render.
  children: PropTypes.node,
  // A list of key/value pairs that are used to generate subsections (preference over children).
  columns: PropTypes.arrayOf(
    PropTypes.shape({
      label: PropTypes.string,
      value: PropTypes.any
    })
  ),
  id: PropTypes.string
};
