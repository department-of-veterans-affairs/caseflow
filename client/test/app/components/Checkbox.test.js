import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { axe } from 'jest-axe';

import { Checkbox } from 'app/components/Checkbox';

const defaults = {
  name: 'field1',
  value: 'foo',
};

describe('Checkbox', () => {
  const handleChange = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = (props = { name: defaults.name }) => {
    const utils = render(
      <Checkbox name={defaults.name} onChange={handleChange} {...props} />
    );
    const input = utils.getByLabelText(
      props.label ?? props.name ?? defaults.name
    );

    return {
      input,
      ...utils,
    };
  };

  it('renders correctly', async () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  describe('label', () => {
    it('uses name for default label', async () => {
      setup();

      expect(screen.queryByLabelText(defaults.name)).toBeTruthy();
    });

    it('uses label prop if set', async () => {
      const label = 'lorem ipsum';

      setup({ label });

      expect(screen.queryByText(defaults.name)).not.toBeTruthy();
      expect(screen.queryByLabelText(label)).toBeTruthy();
    });
  });

  it('shows error message when set', async () => {
    const errorMessage = 'danger, danger!';

    setup({ errorMessage });

    expect(screen.queryByText(errorMessage)).toBeTruthy();
  });

  describe('controlled', () => {
    it('sets input value from props', async () => {
      const { input } = setup({ value: true });

      expect(input).toBeChecked();
    });

    it('correctly calls onChange', async () => {
      const { input } = setup({ value: false });

      expect(input).not.toBeChecked();

      await userEvent.click(input);

      // Calls onChange handler
      expect(handleChange).toHaveBeenCalledTimes(1);

      // While we aren't updating value, handleChange is still getting called
      expect(handleChange).toHaveBeenLastCalledWith(true, expect.anything());

      // However, since we didn't update the value, it won't be checked
      expect(input).not.toBeChecked();
    });
  });

  describe('uncontrolled', () => {
    it('natively updates input value if `value` prop not set', async () => {
      const { input } = setup();

      expect(input).not.toBeChecked();
      await userEvent.click(input);

      expect(input).toBeChecked();
    });
  });
});
