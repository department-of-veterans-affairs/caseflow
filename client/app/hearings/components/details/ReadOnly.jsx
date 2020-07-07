import React from 'react';
import { marginTop } from './style';
import PropTypes from 'prop-types';

/**
 * Read Only component
 * @param {Object} props -- Label and child nodes
 * @component
 */
export const ReadOnly = ({ label, text }) => (
  <div {...marginTop(25)}>
    {label && <strong>{label}</strong>}
    {text && <pre>{text}</pre>}
  </div>
);

ReadOnly.propTypes = {
  text: PropTypes.node,
  label: PropTypes.string,
};
