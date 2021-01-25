import React from 'react';
import { axe } from 'jest-axe';
import { screen, render } from '@testing-library/react';

import AddressForm from 'app/components/AddressForm';

describe('AddressForm', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const defaultProps = {
    organization: false,
  };

  const setup = (props = { ...defaultProps }) => {
    return render(<AddressForm {...props} />);
  };

  it('renders correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
