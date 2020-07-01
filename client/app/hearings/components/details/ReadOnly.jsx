import React from 'react';
import { marginTop } from './style';
import PropTypes from 'prop-types';

/**
 * Read Only component
 * @param {Object} props -- Label and child nodes
 * @component
 */
export const ReadOnly = ({ label, children }) => (
  <div {...marginTop(25)}>
    <strong>{label}</strong>
    {children}
  </div>
);

ReadOnly.propTypes = {
  label: PropTypes.string.isRequired,
  children: PropTypes.node.isRequired,
};
