import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ApiUtil from 'app/util/ApiUtil';

import SelectConferenceTypeRadioField from 'app/queue/SelectConferenceTypeRadioField';

const createSpy = () => jest.spyOn(ApiUtil, 'patch').
  mockImplementation(() => jest.fn(() => Promise.resolve(
    {
      body: { }
    }
  )));

const defaults = {
  name: 'field1',
  value: '1',
  options: [
    { displayText: 'Pexip',
      value: 'pexip' },
    { displayText: 'Webex',
      value: 'webex' },
  ],
};

describe('SelectConferenceTypeRadioField', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setupComponent = (props = {
    user: {
      attributes: {
        id: 1
      }
    },
    meetingType: 'pexip',
    organization: 'my org'
  }) => {
    const utils = render(
      <SelectConferenceTypeRadioField
        name={defaults.name}
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

  it('changes values by radio button selected', () => {
    let requestPatchSpy = createSpy();

    setupComponent();

    const webexRadioButton = screen.getByRole('radio', { name: 'Webex' });
    const pexipRadioButton = screen.getByRole('radio', { name: 'Pexip' });

    expect(webexRadioButton).not.toHaveAttribute('checked', '');
    expect(pexipRadioButton).toHaveAttribute('checked', '');

    userEvent.click(webexRadioButton);

    expect(requestPatchSpy.mock.calls[0][1].data.attributes.meeting_type).toBe('webex');

    userEvent.click(pexipRadioButton);

    expect(requestPatchSpy.mock.calls[1][1].data.attributes.meeting_type).toBe('pexip');
  });
});
