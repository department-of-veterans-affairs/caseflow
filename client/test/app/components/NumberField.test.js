import React from 'react';

import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import NumberField from 'app/components/NumberField';

describe('NumberField', () => {
  const props = {
    label: 'Enter the number of things',
    name: 'number-things',
    useAriaLabel: true,
    isInteger: true,
    value: 4,
    onChange: () => {}
  };

  it('renders correctly', () => {
    const { container } = render(<NumberField {...props} />);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = render(<NumberField {...props} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
