// @flow
import * as React from 'react';
import { css } from 'glamor';

import type {
  Address as AddressType
} from '../types/models';

const addressIndentStyling = (secondLine) => css({
  marginLeft: secondLine ? '7.5em' : 0
});

type Props = {|
  address: AddressType
|};

export class Address extends React.PureComponent<Props> {
  render = () => {
    const {
      address_line_1: addressLine1,
      address_line_2: addressLine2,
      city,
      state,
      zip,
      country
    } = this.props.address;
    const streetAddress = addressLine2 ? `${addressLine1} ${addressLine2}` : addressLine1;

    return <React.Fragment>
      {streetAddress && <React.Fragment><span>{streetAddress},</span><br /></React.Fragment>}
      <span {...addressIndentStyling(streetAddress)}>{city}, {state} {zip} {country === 'USA' ? '' : country}</span>
    </React.Fragment>;
  };
}

export default Address;
