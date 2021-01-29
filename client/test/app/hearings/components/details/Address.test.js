import React from 'react';
import { shallow } from 'enzyme';

import { AddressLine } from 'app/hearings/components/details/Address';
import { ReadOnly } from 'app/hearings/components/details/ReadOnly';
import { anyUser } from 'test/data/user';

describe('AddressLine', () => {
  test('Matches snapshot with default props', () => {
    // Render the address component
    const address = shallow(
      <AddressLine
        name={anyUser.name}
        addressLine1={anyUser.addressLine1}
        addressState={anyUser.addressState}
        addressCity={anyUser.addressCity}
        addressZip={anyUser.addressZip}
      />
    );
    const readOnly = address.find(ReadOnly);

    // Assertions
    expect(address).toMatchSnapshot();
    expect(readOnly).toHaveLength(1);
    expect(readOnly.prop('text')).toEqual(
      `${anyUser.name}\n${anyUser.addressLine1}\n${anyUser.addressCity}, ${
        anyUser.addressState
      } ${anyUser.addressZip}`
    );
  });
});
