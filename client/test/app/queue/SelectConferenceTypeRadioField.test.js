import React from 'react';
import { render } from '@testing-library/react';

import SelectConferenceTypeRadioField from 'app/queue/SelectConferenceTypeRadioField';

const defaults = {
  name: 'field1',
  value: 'option2',
  options: [
    { displayText: 'Option 1',
      value: 'option1' },
    { displayText: 'Option 2',
      value: 'option2' },
  ],
};

describe('SelectConferenceTypeRadioField', () => {
  const handleChange = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = (props = {}) => {
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
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });
});
