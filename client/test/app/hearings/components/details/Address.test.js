import React from 'react';
import { render, screen } from '@testing-library/react';

import { AddressLine } from 'app/hearings/components/details/Address';
import { ReadOnly } from 'app/hearings/components/details/ReadOnly';
import { anyUser } from 'test/data/user';

describe('AddressLine', () => {
  test('Matches snapshot with default props', () => {
    // Render the address component
    const { asFragment } = render(
      <AddressLine
        name={anyUser.name}
        addressLine1={anyUser.addressLine1}
        addressState={anyUser.addressState}
        addressCity={anyUser.addressCity}
        addressZip={anyUser.addressZip}
      />
    );

    const addressText = `${anyUser.name}\n${anyUser.addressLine1}\n${anyUser.addressCity}, ${anyUser.addressState} ${anyUser.addressZip}`;

    // Assertions
    const readOnly = screen.getByText(addressText);
    expect(readOnly).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });
});
