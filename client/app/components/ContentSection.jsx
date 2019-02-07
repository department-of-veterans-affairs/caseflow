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
  marginBottom: '3rem',
  padding: '1rem 2rem'
});

export default class ContentSection extends React.Component {
  render() {
    return <div className="cf-app-segment">
      <h2 {...sectionHeadingStyling}>{this.props.header}</h2>
      <div {...sectionSegmentStyling}>{this.props.content}</div>
    </div>;
  }
}

ContentSection.propTypes = {
  header: PropTypes.object,
  content: PropTypes.object
};
