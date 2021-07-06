import React from 'react';
import { marginTop } from './style';
import PropTypes from 'prop-types';

/**
 * Read Only component
 * @param {Object} props -- Label and child nodes
 * @component
 */
export const ReadOnly = ({ className, label, text, unformatted, spacing = 25 }) => (
  <div {...marginTop(spacing)} className={className}>
    {label && <strong>{label}</strong>}
    {text && !unformatted && <pre>{text}</pre>}
    {text && unformatted && <div>{text}</div>}
  </div>
);

ReadOnly.propTypes = {
  spacing: PropTypes.number,
  unformatted: PropTypes.bool,
  text: PropTypes.node,
  label: PropTypes.string,
  className: PropTypes.string,
};
