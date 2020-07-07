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
}) => {
  // Handle any missing address fields
  const format = (field) => (field ? `${field}\n` : '');

  return (
    /* eslint-disable-next-line no-undefined */
    addressLine1 !== undefined && (
      <ReadOnly
        label={label}
        text={`${format(name)}${format(addressLine1)}${addressCity}, ${addressState} ${addressZip}`} />
    )
  );
};

AddressLine.propTypes = {
  addressLine1: PropTypes.string.isRequired,
  name: PropTypes.string,
  addressState: PropTypes.string,
  addressCity: PropTypes.string,
  addressZip: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  label: PropTypes.string,
};
