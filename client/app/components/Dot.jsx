import React from 'react';
import PropTypes from 'prop-types';

export const Dot = ({ spacing }) => (
  <span style={{ margin: `0 ${spacing || 0}px` }}>&#183;</span>
);

Dot.propTypes = {
  spacing: PropTypes.number
};
