import React from 'react';
import PropTypes from 'prop-types';

import { claimantPropTypes } from './utils';

export const AddressBlock = ({ entity }) => (
  <>
    {entity.partyType === 'organization' && <div>{entity.organization}</div>}
    {entity.partyType === 'individual' && (
      <div>{`${entity.firstName} ${entity.middleName} ${entity.lastName}`}</div>
    )}
    <div>{entity.address1}</div>
    {entity.address2 && <div>{entity.address2}</div>}
    {entity.address3 && <div>{entity.address3}</div>}
    <div>
      {`${entity.city}, ${entity.state} ${entity.country} ${entity.zip}`}
    </div>
    {entity.phoneNumber && <div>{entity.phoneNumber}</div>}
  </>
);

AddressBlock.propTypes = {
  entity: PropTypes.shape(claimantPropTypes),
};
