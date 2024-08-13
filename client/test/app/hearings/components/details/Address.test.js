import React from 'react';
import { render, screen } from '@testing-library/react';

import { AddressLine } from 'app/hearings/components/details/Address';
import { ReadOnly } from 'app/hearings/components/details/ReadOnly';
import { anyUser } from 'test/data/user';

const convertRegex = (str) => {
  return new RegExp(str, 'i');
}

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

    expect(screen.getByText(convertRegex(anyUser.name))).toBeInTheDocument();
    expect(screen.getByText(convertRegex(anyUser.addressLine1))).toBeInTheDocument();
    expect(screen.getByText(convertRegex(`${anyUser.addressCity}, ${anyUser.addressState} ${anyUser.addressZip}`))).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });
});
