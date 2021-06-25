import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';
import userEvent from '@testing-library/user-event';

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

  it('calls onClick when clicked', async () => {
    const onClick = jest.fn();

    setup({ onClick });

    const buttonElement = screen.getByRole('button');

    expect(buttonElement).toBeInTheDocument();
    expect(onClick).toHaveBeenCalledTimes(0);

    await userEvent.click(buttonElement);
    expect(onClick).toHaveBeenCalledTimes(1);
  });

  it('respects loading prop', () => {
    const loading = true;

    setup({ loading });

    const loadingText = 'Loading...';
    const loadingTextElement = screen.getByText(loadingText);

    expect(loadingTextElement).toBeInTheDocument();
  });
  it('respects disabled prop and removes other classes when disabled', () => {
    const disabled = true;

    setup({ disabled });

    const buttonElement = screen.getByRole('button');

    expect(buttonElement.classList.contains('usa-button-disabled')).toBeTruthy();
    expect(buttonElement.classList.contains('usa-button-primary')).toBeFalsy();
  });
});
