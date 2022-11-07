import React from 'react';
import PropTypes from 'prop-types';

import { claimantPropTypes } from './utils';

export const AddressBlock = ({ entity }) => {
  const isOrg = entity.partyType === 'organization';
  const cityString = entity.city ? `${entity.city},` : '';

  return (
    <>
      {isOrg && <div>{entity.name}</div>}
      {!isOrg && (
        <div>{`${entity.title ?? ''} ${entity.firstName ?? ''}
        ${entity.middleName ?? ''} ${entity.lastName ?? ''}`}</div>
      )}
      <div>{entity.addressLine1 ?? ''}</div>
      {entity.addressLine2 && <div>{entity.addressLine2}</div>}
      {entity.addressLine3 && <div>{entity.addressLine3}</div>}
      <div>
        {`${cityString} ${entity.state ?? ''} ${entity.zip ?? ''} ${
          entity.country
        }`}
      </div>
      {entity.phoneNumber && <div>{entity.phoneNumber}</div>}
    </>
  );
};

AddressBlock.propTypes = {
  entity: PropTypes.shape(claimantPropTypes),
};
