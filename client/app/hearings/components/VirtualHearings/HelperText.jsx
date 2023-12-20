import React from 'react';
import PropTypes from 'prop-types';

export const HelperText = ({ label }) => (
  <div className="helper-text" >
    {label}
  </div>
);

HelperText.propTypes = {
  label: PropTypes.string,
};
