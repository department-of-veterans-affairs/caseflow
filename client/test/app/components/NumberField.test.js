import React from 'react';

import { render } from '@testing-library/react';
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
    value: 4,
    onChange: { handleChange }
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

  /*
  it('accepts typing in an integer', async () => {
    const { input } = setup();

    expect(input.value).toBe('4');
    await userEvent.type(input, '6');
    expect(handleChange).toHaveBeenCalled();
    expect(input.value).toBe('6');
  });
  */
  it('rejects typing in a letter', () => {});
  it('rejects typing in a symbol', () => {});
  it('rejects typing in a decimal', () => {});
});
