import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { COLORS } from '../constants/AppConstants';

export const sectionHeadingStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  border: `1px solid ${COLORS.GREY_LIGHT}`,
  borderBottom: 0,
  borderRadius: '0.5rem 0.5rem 0 0',
  margin: 0,
  padding: '1rem 2rem'
});

export const sectionSegmentStyling = css({
  border: `1px solid ${COLORS.GREY_LIGHT}`,
  borderTop: '0px',
  padding: '1rem 2rem'
});

export const ContentSection = ({ header, children, content }) => (
  <div className="cf-app-segment">
    <h2 {...sectionHeadingStyling}>{header}</h2>
    <div {...sectionSegmentStyling}>{content || children}</div>
  </div>
);

ContentSection.propTypes = {
  header: PropTypes.object,
  children: PropTypes.node,
  content: PropTypes.object
};
