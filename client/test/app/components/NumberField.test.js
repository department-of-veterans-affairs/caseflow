import React from 'react';

import { render, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import NumberField from 'app/components/NumberField';

describe('NumberField', () => {
  const handleChange = jest.fn();
  const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();

  const defaults = {
    label: 'Enter the number of things',
    name: 'number-things',
    useAriaLabel: true,
    isInteger: true,
    onChange: handleChange
  };

  const setup = (props = {}) => {

    const utils = render(
      <NumberField {...defaults} {...props} />
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

  it('requires onChange function if readOnly is false', () => {

    setup({ readOnly: false, onChange: null });

    expect(consoleErrorSpy).toHaveBeenCalled();

    consoleErrorSpy.mockClear();
  });

  it('does not require onChange if readOnly is true', () => {

    setup({ readOnly: true, onChange: null });

    expect(consoleErrorSpy).not.toHaveBeenCalled();

    consoleErrorSpy.mockClear();
  });

  // This functionality doesn't seem to be used, is likely deprecated
  describe('allows non-integer input when isInteger is false', () => {
    it('accepts a decimal', async () => {
      const { input } = setup({ isInteger: false });

      expect(input.value).toBe('');
      await userEvent.type(input, '2.4');
      expect(handleChange).toHaveBeenCalledWith(2.4);
    });
  });
  describe('only accepts integer values when isInteger is true', () => {
    it('accepts an integer', async () => {
      const { input } = setup();

      expect(input.value).toBe('');
      await userEvent.type(input, '6');
      expect(handleChange).toHaveBeenCalledWith(6);
    });

    it('rejects a letter', async () => {
      const { input } = setup();

      expect(input.value).toBe('');
      await userEvent.type(input, 'a');
      expect(handleChange).toHaveBeenCalledWith('');
    });

    it('rejects a symbol', async () => {
      const { input } = setup();

      expect(input.value).toBe('');
      await userEvent.type(input, '-');
      expect(handleChange).toHaveBeenCalledWith('');
    });
    it('rejects a decimal', async() => {
      const { input } = setup();

      expect(input.value).toBe('');
      await userEvent.type(input, '0.4');
      expect(handleChange).toHaveBeenCalledWith('');
    });
  });
});
