import React from 'react';
import PropTypes from 'prop-types';

export const FormLabel = ({ label, name, required, optional }) => (
  <span>
    {label || name}
    {required && <span className="cf-required">Required</span>}
    {optional && <span className="cf-optional">Optional</span>}
  </span>
);

FormLabel.propTypes = {
  label: PropTypes.oneOfType([PropTypes.string, PropTypes.element]),
  name: PropTypes.string,
  optional: PropTypes.bool,
  required: PropTypes.bool,
};
