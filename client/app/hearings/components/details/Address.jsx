import React from 'react';
import PropTypes from 'prop-types';

import { fullWidth } from './style';

/**
 * Address Line component
 * @param {Object} props -- Address display details
 */
export const AddressLine = ({ name, addressLine1, addressState, addressCity, addressZip }) => (
  <div>
    <span {...fullWidth}>{name}</span>
    <span {...fullWidth}>{addressLine1}</span>
    <span {...fullWidth}>
      {addressCity}, {addressState} {addressZip}
    </span>
  </div>
);

AddressLine.propTypes = {
  name: PropTypes.string.isRequired,
  addressLine1: PropTypes.string.isRequired,
  addressState: PropTypes.string.isRequired,
  addressCity: PropTypes.string.isRequired,
  addressZip: PropTypes.string.isRequired,
};
