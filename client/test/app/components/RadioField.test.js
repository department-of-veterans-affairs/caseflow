import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { axe } from 'jest-axe';

import { RadioField } from 'app/components/RadioField';

const defaults = {
  name: 'field1',
  value: 'option2',
  options: [
    { displayText: 'Option 1', value: 'option1' },
    { displayText: 'Option 2', value: 'option2' },
    { displayText: 'Option 3', value: 'option3' },
  ],
};

describe('RadioField', () => {
  const handleChange = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = (props = {}) => {
    const utils = render(
      <RadioField
        name={defaults.name}
        onChange={handleChange}
        options={defaults.options}
        {...props}
      />
    );
    const inputs = utils.getAllByRole('radio');

    return {
      inputs,
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
    it('uses name for default label/legend for group', async () => {
      setup();

      expect(screen.queryByText(defaults.name)).toBeTruthy();
    });

    it('uses label prop if set', async () => {
      const label = 'lorem ipsum';

      setup({ label });

      expect(screen.queryByText(defaults.name)).not.toBeTruthy();
      expect(screen.queryByText(label)).toBeTruthy();
    });
  });

  it('shows error message when set', async () => {
    const errorMessage = 'danger, danger!';

    setup({ errorMessage });

    expect(screen.queryByText(errorMessage)).toBeTruthy();
  });

  it('displays help text for option if set', async () => {
    const options = [...defaults.options];
    const helpText = 'This needs explanation';

    options[1].help = helpText;
    setup({ ...defaults, options });

    expect(screen.queryByText(helpText)).toBeTruthy();
  });

  describe('controlled', () => {
    it('sets input value from props', async () => {
      const { inputs } = setup({ value: defaults.value });

      const checked = inputs.filter((el) => el.checked);

      expect(checked.length).toBe(1);
      expect(
        screen.getByLabelText(defaults.options[1].displayText).checked
      ).toBe(true);
    });

    it('correctly calls onChange', async () => {
      const { inputs } = setup({ value: null });

      const opt = defaults.options[1];

      const checkedBefore = inputs.filter((el) => el.checked);

      expect(checkedBefore.length).toBe(0);

      await userEvent.click(screen.getByLabelText(opt.displayText));

      // Calls onChange handler
      expect(handleChange).toHaveBeenCalledTimes(1);

      // While we aren't updating value, handleChange is still getting called
      expect(handleChange).toHaveBeenLastCalledWith(opt.value);

      const checkedAfter = inputs.filter((el) => el.checked);

      // Value should not have been updated yet
      expect(checkedAfter.length).toBe(0);
    });
  });

  describe('uncontrolled', () => {
    it('natively updates input value if `value` prop not set', async () => {
      const { inputs } = setup();

      const opt = defaults.options[1];
      const checked = () => inputs.filter((el) => el.checked);

      expect(checked().length).toBe(0);
      await userEvent.click(screen.getByLabelText(opt.displayText));

      expect(checked().length).toBe(1);
    });
  });
});
