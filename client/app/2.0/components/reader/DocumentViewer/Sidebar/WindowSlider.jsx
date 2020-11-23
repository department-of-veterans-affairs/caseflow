// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

/**
 * Window Slider Component for the Document Screen
 * @param {Object} props -- Contains overscan value and function to modify
 */
export const WindowSlider = ({ setOverscanValue, windowingOverscan }) => (
  <span>
    <input
      type="range"
      value={windowingOverscan}
      min="1"
      max="100"
      onChange={({ target }) => setOverscanValue(target.value)}
    />
      Overscan: {windowingOverscan}
  </span>
);

WindowSlider.propTypes = {
  windowingOverscan: PropTypes.string,
  setOverscanValue: PropTypes.func,
};
