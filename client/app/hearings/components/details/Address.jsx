import React from 'react';
import PropTypes from 'prop-types';

import { ReadOnly } from './ReadOnly';

/**
 * Address Line component
 * @param {Object} props -- Address display details
 */
export const AddressLine = ({
  name,
  label,
  addressLine1,
  addressState,
  addressCity,
  addressZip,
  ...props
}) => {
  // Handle any missing address fields
  const format = (field) => (field ? `${field}\n` : '');
  const text = addressLine1 && addressState && addressCity && addressZip ?
    `${format(name)}${format(addressLine1)}${addressCity}, ${addressState} ${addressZip}` :
    format(name);

  return (
    <ReadOnly
      {...props}
      label={label}
      text={text} />
  );
};

AddressLine.propTypes = {
  addressLine1: PropTypes.string,
  name: PropTypes.string,
  addressState: PropTypes.string,
  addressCity: PropTypes.string,
  addressZip: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  label: PropTypes.string,
};
