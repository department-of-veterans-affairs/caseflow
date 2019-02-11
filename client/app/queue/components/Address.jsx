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
      address_line_3: addressLine3,
      city,
      state,
      zip,
      country
    } = this.props.address;

    return <span {...addressIndentStyling}>
      <div>
        <div> {addressLine1}</div>
        <div> {addressLine2 && <React.Fragment><span>{addressLine2}</span></React.Fragment>}</div>
        <div> {addressLine3 && <React.Fragment><span>{addressLine3}</span></React.Fragment>}</div>
        <div> <span>{city}, {state} {zip} {country === 'USA' ? '' : country}</span></div>
      </div>
    </span>;

  };
}
