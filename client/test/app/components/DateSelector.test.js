import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { axe } from 'jest-axe';

import { DateSelector } from 'app/components/DateSelector';

const defaults = {
  name: 'date1',
  value: '06/15/2020',
};

describe('DateSelector', () => {
  const handleChange = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = (props = {}) => {
    const utils = render(
      <DateSelector name={defaults.name} onChange={handleChange} {...props} />
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

      expect(screen.queryByLabelText(defaults.name)).not.toBeTruthy();
      expect(screen.queryByLabelText(label)).toBeTruthy();
    });
  });

  it('shows error message when set', async () => {
    const errorMessage = 'danger, danger!';

    setup({ errorMessage });

    expect(screen.queryByText(errorMessage)).toBeTruthy();
  });

  it('passes along other input props', async () => {
    const props = {
      name: 'bar',
      readOnly: true,
      placeholder: 'foo bar',
      title: 'input title',
      inputProps: {
        type: 'date',
      },
    };
    const { input } = setup(props);

    expect(input).toHaveAttribute('name', props.name);
    expect(input.readOnly).toBe(props.readOnly);
    expect(input).toHaveAttribute('placeholder', props.placeholder);
    expect(input).toHaveAttribute('title', props.title);

    // Verify inputProps
    expect(input).toHaveAttribute('type', 'date');
  });

  describe('controlled', () => {
    it('sets input value from props', async () => {
      const { input } = setup({ value: defaults.value });

      expect(input).toHaveValue(defaults.value);
    });

    it('correctly calls onChange', async () => {
      const { input } = setup({ value: '' });

      expect(input).toHaveValue('');

      await userEvent.type(input, defaults.value);

      // Calls onChange handler each time a key is pressed
      expect(handleChange).toHaveBeenCalledTimes(defaults.value.length);

      // While we aren't updating value, handleChange is still getting called
      expect(handleChange).toHaveBeenLastCalledWith(defaults.value[defaults.value.length - 1]);

      // Value should not have been updated yet
      expect(input).toHaveValue('');
    });
  });

  describe('uncontrolled', () => {
    it('natively updates input value if `value` prop not set', async () => {
      const { input } = setup();

      expect(input).toHaveValue('');
      await userEvent.type(input, defaults.value);

      expect(input).toHaveValue(defaults.value);
    });
  });

  // These tests were originally karma tests, but those karma tests
  // were commented out for 4 years. They test the regex's behavior.
  describe('regex behaviors', () => {
    // I would like to write for this test:
    // expect(stateICantFind).toEqual('12/dd/yyyy')
    it('adds a slash and doesnt error when a month is entered', async () => {
      const { input } = setup();

      expect(input).toHaveValue('');
      await userEvent.type(input, '12');

      expect(input.value).toEqual('12'); // This gets formatted to 12/dd/yyyy
      expect(handleChange).toHaveBeenLastCalledWith('12/');
    });

    // I would like to write for this test:
    // expect(stateICantFind).toEqual('02/02/yyyy')
    it('rejects a two digit month that doesnt start with 1', async () => {
      const { input } = setup();

      expect(input).toHaveValue('');
      await userEvent.type(input, '22');

      expect(input.value).toEqual('22'); // This gets formatted to 02/02/yyyy
      expect(handleChange).toHaveBeenLastCalledWith('');
    });
  });
});
