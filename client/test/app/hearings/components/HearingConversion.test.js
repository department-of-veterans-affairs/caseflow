import React from 'react';

import { HearingConversion } from 'app/hearings/components/HearingConversion';
import { detailsStore, hearingDetailsWrapper } from 'test/data/stores/hearingsStore';

import { render as rtlRender, screen } from '@testing-library/react';

import { userWithJudgeRole, amaHearing, vsoUser, anyUser } from 'test/data';
import { HEARING_CONVERSION_TYPES } from 'app/hearings/constants';
import * as DateUtil from 'app/util/DateUtil';
import COPY from '../../../../../client/COPY.json'
import { Wrapper, customRender } from '../../../helpers/testHelpers';

const updateSpy = jest.fn();
const defaultTitle = 'Convert to Virtual';
const mockUpdateCheckboxes = jest.fn();
jest.mock('superagent');

const mockJudges = [
  { id: 'judge1', name: 'Judge Judy' },
  { id: 'judge2', name: 'Judge Dredd' },
];

// Setup the mock implementation
superagent.get.mockImplementation((url) => {
  const mockResponse = { body: mockJudges };
  const mockRequest = {
    set: jest.fn().mockReturnThis(),
    query: jest.fn().mockReturnThis(),
    timeout: jest.fn().mockReturnThis(),
    on: jest.fn().mockReturnThis(),
    use: jest.fn().mockReturnThis(), // Add the `use` method
    then: jest.fn((callback) => {
      callback(mockResponse);
      return Promise.resolve(mockResponse);
    }),
    catch: jest.fn(() => Promise.resolve(mockResponse)),
  };

  if (url === '/users?role=Judge') {
    return mockRequest;
  } else {
    return Promise.reject(new Error('connect ECONNREFUSED 127.0.0.1:80'));
  }
});


function customRender(ui, { wrapper: Wrapper, wrapperProps, ...options }) {
  if (Wrapper) {
    ui = <Wrapper {...wrapperProps}>{ui}</Wrapper>;
  }
  return rtlRender(ui, options);
}

const Wrapper = ({ children, user, hearing, judge, store }) => {
  const HearingDetails = hearingDetailsWrapper(user, hearing, judge);
  return (
    <HearingDetails store={store}>
      {children}
    </HearingDetails>
  );
};

describe('HearingConversion', () => {
  test('Matches snapshot with default props', () => {
    const { asFragment } = customRender(
      <HearingConversion
        scheduledFor={amaHearing.scheduledFor.toString()}
        type={HEARING_CONVERSION_TYPES[0]}
        title={defaultTitle}
        update={updateSpy}
        hearing={amaHearing}
        updateCheckboxes= {mockUpdateCheckboxes}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          store: detailsStore,
          user: anyUser,
          hearing: amaHearing,
          judge: userWithJudgeRole
        },
      }
    );

    // Assertions
    // Ensure the radio buttons are hidden
    const allRadioButtons = screen.queryAllByRole('radio');
    expect(allRadioButtons).toHaveLength(0);

    const veteranHeader = screen.getByRole('heading', { name: 'Veteran' });
    const poaHeader = screen.getByRole('heading', { name: 'Power of Attorney (POA)' });
    const vljHeader = screen.getByRole('heading', { name: 'Veterans Law Judge (VLJ)' });
    expect(veteranHeader).toBeInTheDocument();
    expect(poaHeader).toBeInTheDocument();
    expect(vljHeader).toBeInTheDocument();

    // // Check for Instructional Text for Non-VSO User
    expect(screen.getByText('Email notifications will be sent to the Veteran, POA / Representative, and Veterans Law Judge (VLJ).')).toBeInTheDocument();

    const hearingDateElement = screen.getByText(DateUtil.formatDateStr(amaHearing.scheduledFor));
    expect(hearingDateElement).toBeInTheDocument();

    const AddressLineElementOne = screen.getByText('Bob Smith 9999 MISSION ST SAN FRANCISCO, CA 94103');
    expect(AddressLineElementOne).toBeInTheDocument();
    const AddressLineElementTwo = screen.getByText('PARALYZED VETERANS OF AMERICA, INC.');
    expect(AddressLineElementTwo).toBeInTheDocument();

    const veteranTimezone = screen.getByRole('combobox', { name: 'Veteran Timezone Required' });
    const representativeTimezone = screen.getByRole('combobox', { name: 'POA/Representative Timezone Required' });
    expect(veteranTimezone).toBeInTheDocument();
    expect(representativeTimezone).toBeInTheDocument();

    const emailFields = screen.getAllByRole('textbox');
    expect(emailFields).toHaveLength(2);

    const vljCombobox = screen.getByRole('combobox', { name: 'VLJ' });
    expect(vljCombobox).toBeInTheDocument();

    expect(screen.queryAllByLabelText('vsoCheckboxes')).toHaveLength(0);
    expect(screen.queryAllByRole('checkbox')).toHaveLength(0);

    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays email fields when hearing type is switched from virtual', () => {
    const { asFragment } = customRender(
      <HearingConversion
        scheduledFor={amaHearing.scheduledFor.toString()}
        type={HEARING_CONVERSION_TYPES[1]}
        title={defaultTitle}
        update={updateSpy}
        hearing={amaHearing}
        updateCheckboxes= {mockUpdateCheckboxes}
        userVsoEmployee= {false}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          store: detailsStore,
          user: anyUser,
          hearing: amaHearing,
          judge: userWithJudgeRole
        },
      }
    );

    // Assertions
    const allRadioButtons = screen.getAllByRole('radio');
    allRadioButtons.forEach((radioButton) => {
      expect(radioButton).toBeInTheDocument();
    });

    // Ensure the judge dropdown section is hidden
    const vljElement = screen.queryByText('Veterans Law Judge (VLJ)');
    expect(vljElement).not.toBeInTheDocument();

    // Ensure the emails are displayed but not the judge
    const veteranTimezone = screen.getByRole('combobox', { name: 'Veteran Timezone Optional' });
    const representativeTimezone = screen.getByRole('combobox', { name: 'POA/Representative Timezone Required' });
    expect(veteranTimezone).toBeInTheDocument();
    expect(representativeTimezone).toBeInTheDocument();

    const emailFields = screen.getAllByRole('textbox');
    expect(emailFields).toHaveLength(2);

    const vljCombobox = screen.queryAllByRole('combobox', { name: 'VLJ' });
    expect(vljCombobox).toHaveLength(0);

    expect(asFragment()).toMatchSnapshot();
  });

  test('When a VSO user converts to virtual, the checkboxes and banner appear on the form', () => {
    customRender(
      <HearingConversion
        scheduledFor={amaHearing.scheduledFor.toString()}
        type={HEARING_CONVERSION_TYPES[0]}
        title={defaultTitle}
        update={updateSpy}
        hearing={amaHearing}
        updateCheckboxes= {mockUpdateCheckboxes}
        userVsoEmployee
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          store: detailsStore,
          user: vsoUser,
          hearing: amaHearing,
          // judge: userWithJudgeRole
        },
      }
    );

    //  expect both checkboxes to show
    const vsoCheckboxes = screen.getAllByRole('checkbox');
    expect(vsoCheckboxes).toHaveLength(2);

    // // expect span text to appear
    expect(screen.getByText(COPY.CONVERT_HEARING_TYPE_SUBTITLE_3)).toBeInTheDocument();
  });
});
