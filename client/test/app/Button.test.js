import React from 'react';
import { render } from '@testing-library/react';
import { axe } from 'jest-axe';
// import userEvent, { specialChars } from '@testing-library/user-event';

import Button from '../../app/components/Button';

describe('Button', () => {
  const defaults = {
    name: 'test-button',
    ariaLabel: 'test-button-aria',
    children: 'Click me'
  };

  const setup = (props) => {
    const { container } = render(<Button {...defaults} {...props} />);

    return { container };
  };

  it('renders properly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
