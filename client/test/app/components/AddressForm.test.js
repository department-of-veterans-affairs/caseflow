import React from 'react';
import { axe } from 'jest-axe';
import { screen, render } from '@testing-library/react';

import AddressForm from 'app/components/AddressForm';

describe('AddClaimantForm', () => {
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

  describe('organization prop toggles address 3 input', () => {
    const address3Text = 'Street address 3';

    it('when true, address 3 is rendered', () => {
      setup({ organization: true });

      const address3 = screen.queryByText(address3Text);

      expect(address3).toBeInTheDocument();
    });

    it('when false, address 3 is not rendered', () => {
      setup({ organization: false });

      const address3 = screen.queryByText(address3Text);

      expect(address3).not.toBeInTheDocument();
    });
  });
});
