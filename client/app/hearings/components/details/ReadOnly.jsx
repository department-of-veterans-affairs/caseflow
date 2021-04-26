import React from 'react';
import { marginTop } from './style';
import PropTypes from 'prop-types';

/**
 * Read Only component
 * @param {Object} props -- Label and child nodes
 * @component
 */
export const ReadOnly = ({ className, label, text, spacing = 25 }) => (
  <div {...marginTop(spacing)} className={className}>
    {label && <strong>{label}</strong>}
    {text && <pre>{text}</pre>}
  </div>
);

ReadOnly.propTypes = {
  spacing: PropTypes.number,
  text: PropTypes.node,
  label: PropTypes.string,
  className: PropTypes.string,
};
