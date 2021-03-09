import React from 'react';
import { render, screen } from '@testing-library/react';
import FilterOption from 'app/components/FilterOption';
import { axe } from 'jest-axe';

describe('FilterOption', () => {
  const props = {
    options: [
      {
        displayText: 'Attorney Legacy Tasks',
        value: 'AttorneyLegacyTask',
        checked: false,
      },
      {
        displayText: 'Establish Claim',
        value: 'EstablishClaim',
        checked: false
      }
    ],
    setSelectedValue: () => {},
  };

  it('renders correctly', () => {
    const { container } = render(<FilterOption {...props} />);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = render(<FilterOption {...props} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('shows all options as unchecked initially', async () => {
    await render(<FilterOption {...props} />);

    const options = props.options;

    options.forEach((opt) => {
      const option = screen.queryByText(opt.displayText);

      expect(option).not.toBeNull();
      expect(option.checked).toBeFalsy();
    });
  });
});
