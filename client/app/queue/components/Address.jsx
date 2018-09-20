// @flow
import * as React from 'react';
import { css } from 'glamor';

import type {
  Address as AddressType
} from '../types/models';

const addressIndentStyling = css({
  display: 'inline-block',
  verticalAlign: 'top'
});

type Props = {|
  address: AddressType
|};

export default class Address extends React.PureComponent<Props> {
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

    return <span {...addressIndentStyling}>
      {streetAddress && <React.Fragment><span>{streetAddress},</span><br /></React.Fragment>}
      <span>{city}, {state} {zip} {country === 'USA' ? '' : country}</span>
    </span>;
  };
}
