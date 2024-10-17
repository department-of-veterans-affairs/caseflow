import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ScheduleVeteranForm } from 'app/hearings/components/ScheduleVeteranForm';
import { amaAppeal, defaultHearing, virtualHearing } from 'test/data';
import { generateAmaTask } from 'test/data/tasks';
import { queueWrapper } from 'test/data/stores/queueStore';
import {
  VIRTUAL_HEARING_LABEL
} from 'app/hearings/constants';
import ApiUtil from 'app/util/ApiUtil';

// Set the spies
const changeSpy = jest.fn();
const submitSpy = jest.fn();
const cancelSpy = jest.fn();
const fetchScheduledHearingsMock = jest.fn();

jest.mock('app/util/ApiUtil', () => ({
  convertToSnakeCase: jest.fn((obj) => obj),
  convertToCamelCase: jest.fn((obj) => obj),
  get: jest.fn().mockResolvedValue({})
}));

const mockResponse = {
  body: {
    filled_hearing_slots: [
      {
        external_id: '123456',
        hearing_time: '09:00',
        issue_count: 3,
        docket_number: '12345678',
        docket_name: 'Legacy',
        poa_name: 'Some POA Name'
      },
      {
        external_id: '789012',
        hearing_time: '10:30',
        issue_count: 2,
        docket_number: '87654321',
        docket_name: 'AMA',
        poa_name: 'Another POA Name'
      }
    ]
  }
};

const convertRegex = (str) => {
  return new RegExp(str, 'i');
};

describe('ScheduleVeteranForm', () => {
  test('Matches snapshot with default props', () => {
    // Render the address component
    const { container, asFragment } = render(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={defaultHearing}
      />,
      {
        wrapper: queueWrapper,
      }
    );

    // Assertions
    expect(screen.getByRole('combobox', { name: 'Hearing Type' })).toBeInTheDocument();
    expect(screen.getByRole('combobox', { name: 'Regional Office' })).toBeInTheDocument();
    expect(container.querySelector('.schedule-veteran-appeals-info')).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: `${amaAppeal.veteranInfo.veteran.full_name}` })).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays hearing form when regional office is selected', async () => {
    // Render the address component
    ApiUtil.get.mockResolvedValue(mockResponse);

    const { container, asFragment } = render(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        fetchScheduledVeterans={fetchScheduledHearingsMock}
        appeal={{
          ...amaAppeal,
          regionalOffice: defaultHearing.regionalOfficeKey,
        }}
        hearing={{
          ...defaultHearing,
          regionalOffice: defaultHearing.regionalOfficeKey,
        }}
        appellantTitle="Veteran"
      />,
      {
        wrapper: queueWrapper,
      }
    );

    // Assertions
    expect(container.querySelector('.schedule-veteran-appeals-info')).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: `${amaAppeal.veteranInfo.veteran.full_name}` })).toBeInTheDocument();
    expect(screen.getByRole('combobox', { name: 'Hearing Location' })).toBeInTheDocument();
    expect(screen.getByRole('combobox', { name: 'Hearing Date' })).toBeInTheDocument();
    expect(screen.queryByRole('combobox', { name: 'Veteran Timezone Required' })).not.toBeInTheDocument();
    expect(screen.queryByRole('combobox', { name: 'POA/Representative Timezone Required' })).not.toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays Virtual Hearing form fields when type is changed to Virtual', () => {
    ApiUtil.get.mockResolvedValue(mockResponse);
    const { container, asFragment, rerender } = render(
      <ScheduleVeteranForm
        virtual
        userCanCollectVideoCentralEmails
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={{
          ...amaAppeal,
          readableHearingRequestType: VIRTUAL_HEARING_LABEL,
        }}
        hearing={{
          ...defaultHearing,
          regionalOffice: defaultHearing.regionalOfficeKey,
          virtualHearing: virtualHearing.virtualHearing
        }}
        appellantTitle="Veteran"
      />,
      {
        wrapper: queueWrapper,
      }
    );

    // Check for virtual hearing fields
    expect(screen.getByRole('combobox', { name: 'Veteran Timezone Required' })).toBeInTheDocument();
    expect(screen.getByRole('combobox', { name: 'POA/Representative Timezone Required' })).toBeInTheDocument();
    expect(screen.getByRole('combobox', { name: 'Hearing Date' })).toBeInTheDocument();

    //  If the hearing is virtual, AppealHearingLocationsDropdown should not be displayed
    expect(screen.queryByRole('combobox', { name: 'Hearing Location' })).not.toBeInTheDocument();

    // Assert that "Hearing Location" is present
    expect(screen.getByText('Hearing Location')).toBeInTheDocument();
    expect(screen.getByText('Virtual')).toBeInTheDocument();
    expect(screen.queryByRole('combobox', { name: 'Veteran Timezone Required' })).toBeInTheDocument();
    expect(screen.queryByRole('combobox', { name: 'POA/Representative Timezone Required' })).toBeInTheDocument();

    rerender(<ScheduleVeteranForm
      virtual
      userCanCollectVideoCentralEmails
      goBack={cancelSpy}
      submit={submitSpy}
      onChange={changeSpy}
      appeal={{
        ...amaAppeal,
        readableHearingRequestType: VIRTUAL_HEARING_LABEL,
      }}
      hearing={{
        ...defaultHearing,
        regionalOffice: 'C',
        virtualHearing: virtualHearing.virtualHearing
      }}
    />,
    {
      wrapper: queueWrapper,
    });

    const regionalOffice = screen.getByRole('combobox', { name: 'Regional Office' });

    fireEvent.keyDown(regionalOffice, { key: 'ArrowDown' });
    const centralOffice = screen.getByRole('option', { name: 'Central' });

    fireEvent.click(centralOffice);

    expect(screen.getByText('Central')).toBeInTheDocument();

    expect(screen.queryByRole('combobox', { name: 'Hearing Date' })).not.toBeInTheDocument();
    expect(
      screen.getByRole('combobox', { name: 'Finding upcoming hearing dates for this regional office...' })
    ).toBeInTheDocument();

    // // Make sure the timezones display after changing to Central
    expect(screen.getByRole('combobox', { name: 'undefined Timezone Required' })).toBeInTheDocument();
    expect(screen.getByRole('combobox', { name: 'POA/Representative Timezone Required' })).toBeInTheDocument();

    const cityStateZip = `${defaultHearing.representativeAddress.city},` +
      ` ${defaultHearing.representativeAddress.state} ` +
      `${defaultHearing.representativeAddress.zip}`;
    const matchingAddresses = screen.queryAllByText(convertRegex(cityStateZip));

    expect(matchingAddresses.length).toBeGreaterThan(0);
    expect(container.querySelector('.schedule-veteran-appeals-info')).toBeInTheDocument();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays error messages when errors are present', () => {
    // Setup the test
    const error = 'Please select hearing day';
    // Render the address component
    const { container, asFragment } = render(
      <ScheduleVeteranForm
        errors={{ hearingDay: error }}
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={{
          ...amaAppeal,
          regionalOffice: defaultHearing.regionalOfficeKey,
        }}
        hearing={{
          ...defaultHearing,
          regionalOffice: defaultHearing.regionalOfficeKey,
        }}
      />,
      {
        wrapper: queueWrapper,
      }
    );

    // Assertions
    expect(container.querySelector('.schedule-veteran-appeals-info')).toBeInTheDocument();
    expect(screen.getByText(error)).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displayes Unschedules Notes input', () => {
    const parentHearingTask = generateAmaTask({
      uniqueId: '3',
      type: 'HearingTask',
      status: 'on_hold',
      unscheduledHearingNotes: {
        notes: 'Preloaded notes'
      }
    });

    const { asFragment } = render(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={defaultHearing}
        hearingTask={parentHearingTask}
      />,
      {
        wrapper: queueWrapper,
      }
    );

    expect(screen.getByRole('textbox', { name: 'Notes' })).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('RO dropdown includes Virtual Hearings as option is type is selected as Virtual', () => {
    const { asFragment } = render(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={defaultHearing}
        virtual
      />,
      {
        wrapper: queueWrapper,
      }
    );

    expect(screen.getByRole('combobox', { name: 'Regional Office' })).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays ReadOnlyHearingTimeWithZone when video is selected and halfDay is true', () => {
    const hearing = {
      ...defaultHearing,
      requestType: 'Video',
      regionalOffice: defaultHearing.regionalOfficeKey,
      hearingDay: {
        hearingId: 1,
        readableRequestType: 'Video',
        beginsAt: '2021-07-29T11:30:00-04:00',
        halfDay: true,
        timezone: 'America/Los_Angeles',
        scheduledFor: '2025-01-01'
      }
    };
    const { asFragment } = render(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={hearing}
        virtual={false}
      />,
      {
        wrapper: queueWrapper,
      }
    );

    expect(screen.queryByRole('combobox', { name: 'Hearing Time' })).not.toBeInTheDocument();
    expect(screen.getByText('8:30 AM Pacific / 11:30 AM Eastern')).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays HearingTime when video is selected and halfDay is false', () => {
    const hearing = {
      ...defaultHearing,
      regionalOffice: defaultHearing.regionalOfficeKey,
      hearingDay: {
        hearingId: 1,
        readableRequestType: 'Video',
        beginsAt: null,
        halfDay: false,
        timezone: 'America/Los_Angeles',
        scheduledFor: '2025-01-01'
      }
    };
    const { asFragment } = render(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={hearing}
        virtual={false}
      />,
      {
        wrapper: queueWrapper,
      }
    );

    expect(screen.getByRole('combobox', { name: 'Hearing Time' })).toBeInTheDocument();
    expect(
      screen.getByRole('radio', { name: '8:30 AM Pacific Time (US & Canada) / 11:30 AM Eastern Time (US & Canada)' })
    ).toBeInTheDocument();
    expect(
      screen.getByRole('radio', { name: '12:30 PM Pacific Time (US & Canada) / 3:30 PM Eastern Time (US & Canada)' })
    ).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  describe('Timezone dropdowns show correct preview times', () => {
    const renderForm = (timezone, regionalOfficeKey, timeString, hearingDate = '2024-10-01') => {
      ApiUtil.get.mockResolvedValue(mockResponse);

      render(
        <ScheduleVeteranForm
          goBack={cancelSpy}
          submit={submitSpy}
          fetchScheduledVeterans={fetchScheduledHearingsMock}
          appeal={{
            ...amaAppeal,
            regionalOffice: defaultHearing.regionalOfficeKey,
            readableHearingRequestType: 'Virtual',
            readableOriginalHearingRequestType: 'Video'
          }}
          hearing={{
            ...defaultHearing,
            regionalOffice: defaultHearing.regionalOfficeKey,
            requestType: 'Virtual',
            hearingDay: {
              ...defaultHearing.hearingDay,
              scheduledFor: hearingDate,
              timezone
            },
            hearingLocation: null,
            scheduledTimeString: timeString
          }}
          virtualHearing={{
            status: 'active'
          }}
          appellantTitle="Veteran"
          userCanCollectVideoCentralEmails
          userCanViewTimeSlots
          virtual
          hearingRequestTypeDropdownCurrentOption={{
            value: true, label: 'Virtual'
          }}
          initialRegionalOffice={regionalOfficeKey}
          onChange={changeSpy}
        />,
        {
          wrapper: queueWrapper,
        }
      );
    };

    test('Boise RO has times persisted correctly when Daylight Savings Time is active', () => {
      renderForm('America/Boise', 'RO47', null);

      const timeSlotButton = screen.getByRole('button', { name: '12:30 PM MDT (2:30 PM EDT)' });

      userEvent.click(timeSlotButton);

      const lastCallArgs = changeSpy.mock.calls[changeSpy.mock.calls.length - 1];

      expect(lastCallArgs[0]).toEqual('scheduledTimeString');
      expect(lastCallArgs[1]).toEqual('12:30 PM Mountain Time (US & Canada)');
    });

    test('Boise RO has times persisted correctly when Daylight Savings Time is NOT active', () => {
      renderForm('America/Boise', 'RO47', null, '2025-01-01');

      const timeSlotButton = screen.getByRole('button', { name: '12:30 PM MST (2:30 PM EST)' });

      userEvent.click(timeSlotButton);

      const lastCallArgs = changeSpy.mock.calls[changeSpy.mock.calls.length - 1];

      expect(lastCallArgs[0]).toEqual('scheduledTimeString');
      expect(lastCallArgs[1]).toEqual('12:30 PM Mountain Time (US & Canada)');
    });

    test('Timezone Dropdowns show accurate time previews', () => {
      renderForm(
        'America/Boise',
        'RO47',
        '12:30 PM Mountain Time (US & Canada)',
        '2024-10-01'
      );
      expect(screen.getAllByText('Pacific Time (US & Canada) (11:30 AM)').length).toBe(2);

    });
  });
});
