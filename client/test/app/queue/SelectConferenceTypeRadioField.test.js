import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import SelectConferenceTypeRadioField from 'app/queue/SelectConferenceTypeRadioField';

const defaults = {
  name: 'field1',
  value: '1',
  options: [
    { displayText: 'Pexip',
      value: '1' },
    { displayText: 'Webex',
      value: '2' },
  ],
};

describe('SelectConferenceTypeRadioField', () => {
  const handleChange = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setupComponent = (props = {}) => {
    const utils = render(
      <SelectConferenceTypeRadioField
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
    const { container } = setupComponent();

    expect(container).toMatchSnapshot();
  });

  it('has the correct default value', async () => {
    expect(defaults.value) === "1";
  })

  it('changes values by radio button selected', async () => {
    setupComponent();
    const webexRadioButton = screen.getByText('Webex');

    await userEvent.click(webexRadioButton);

    expect(defaults.value) === "2";
  })
});
