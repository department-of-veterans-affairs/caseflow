
import React from 'react';

import { fullWidth } from '../details/style';

export const AddressLine = ({
  name,
  addressLine1,
  addressState,
  addressCity,
  addressZip,
}) => (
  <div>
    <span {...fullWidth}>{name}</span>
    <span {...fullWidth}>{addressLine1}</span>
    <span {...fullWidth}>
      {addressCity}, {addressState} {addressZip}
    </span>
  </div>
);
