import React from 'react';
import {
  render,
  fireEvent,
  screen,
  wait,
  waitFor,
} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderHook } from '@testing-library/react-hooks';

import { axe } from 'jest-axe';

import { TextField } from 'app/components/TextField';

const defaults = {
  name: 'field1',
  value: 'foo',
};

describe('TextField', () => {
  const handleChange = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = (props = {}) => {
    const utils = render(
      <TextField name={defaults.name} onChange={handleChange} {...props} />
    );
    const input = utils.getByLabelText(props.label ?? 'field1');

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

      expect(screen.queryByLabelText(defaults.name)).not.toBeTruthy();
      expect(screen.queryByLabelText(label)).toBeTruthy();
    });
  });

  it('shows error message when set', async () => {
    const errorMessage = 'danger, danger!';

    setup({ errorMessage });

    expect(screen.queryByText(errorMessage)).toBeTruthy();
  });

  it('limits max length if set', async () => {
    const maxLength = 3;
    const { input } = setup({ maxLength });

    expect(input.maxLength).toBe(maxLength);

    const text = 'text exceeds maxlength';

    userEvent.type(input, text);
    expect(handleChange).toHaveBeenLastCalledWith(text.substr(0, maxLength));
  });

  describe('controlled', () => {
    it('sets input value from props', async () => {
      const { input } = setup({ value: defaults.value });

      expect(input.value).toBe(defaults.value);
    });

    it('correctly calls onChange', async () => {
      const { input } = setup({ value: '' });

      expect(input.value).toBe('');

      await userEvent.type(input, defaults.value);

      // Calls onChange handler
      expect(handleChange).toHaveBeenCalledTimes(defaults.value.length);

      // Value should not have been updated yet
      expect(input.value).toBe('');
    });
  });
});
