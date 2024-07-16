import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { omit } from 'lodash';
import {
  amaAppeal,
  defaultHearing,
  scheduleHearingDetails,
  virtualHearing,
  hearingDateOptions,
  scheduledHearing,
  scheduleVeteranResponse,
  openHearingAppeal,
  legacyAppeal,
  legacyAppealForTravelBoard
} from 'test/data';
import { queueWrapper, appealsData } from 'test/data/stores/queueStore';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { formatDateStr } from 'app/util/DateUtil';
import ScheduleVeteran from 'app/hearings/components/ScheduleVeteran';
import ApiUtil from 'app/util/ApiUtil';
import * as uiActions from 'app/queue/uiReducer/uiActions';
import { VIDEO_HEARING_LABEL, VIRTUAL_HEARING_LABEL } from 'app/hearings/constants';
import * as utils from 'app/hearings/utils';

// Set the spies
const changeSpy = jest.fn();
const submitSpy = jest.fn();
const cancelSpy = jest.fn();
const defaultError = {
  response: {
    body: {
      errors: [
        {
          code: 500,
        },
      ],
    },
  },
};

// jest.mock('app/util/ApiUtil', () => ({
//   ...jest.requireActual('app/util/ApiUtil'), // Use the actual ApiUtil module for other functions
//   get: jest.fn(), // Mock the `get` function
// }));


jest.spyOn(window, 'analyticsEvent').mockImplementation(() => {});

// const mockHistory = createMemoryHistory();
// jest.mock('react-router-dom', () => ({
//   ...jest.requireActual('react-router-dom'),
//   useHistory: () => mockHistory
// }));

function customRender(ui, { wrapper: Wrapper, wrapperProps, ...options }) {
  if (Wrapper) {
    ui = <Wrapper {...wrapperProps}>{ui}</Wrapper>;
  }
  return render(ui, options);
}

const Wrapper = ({ children, ...props }) => {
  return queueWrapper({ children, ...props });
};

let patchSpy;
const setScheduledHearingMock = jest.fn();
const fetchScheduledHearingsMock = jest.fn();
const errorMessageSpy = jest.spyOn(uiActions, 'showErrorMessage');
const showSuccessMessageSpy = jest.spyOn(uiActions, 'showSuccessMessage');
const getSpy = jest.spyOn(ApiUtil, 'get');

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

describe('ScheduleVeteran', () => {
  jest.spyOn(document, 'getElementById').mockImplementation((id) => {
    if (id === 'email-section') {
      return { scrollIntoView: jest.fn() };
    }
    return null; // Or you can return the original implementation
  });
    patchSpy = jest.spyOn(ApiUtil, 'patch');
    getSpy.mockImplementation(() => Promise.resolve({ body: {}}));

  beforeAll(() => {
    // Necessary because the list of timezones changes depending on the date
    // Timezones are included because of this component hierarchy:
    // ScheduleVeteran -> ScheduleVeteranForm -> AppellantSection -> Timezone
    jest.
      useFakeTimers('modern').
      setSystemTime(new Date('2021-11-01').getTime());
  });

  afterAll(() => {
    // Clear the system time make
    jest.useRealTimers();
    jest.restoreAllMocks();
  });

  test('Matches snapshot with default props', async () => {
    // Render the scheduleVeteran component
    const {container, asFragment} = render(
      <ScheduleVeteran
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={amaAppeal.externalId}
        hearing={defaultHearing}
        scheduledHearing={scheduledHearing}
      />,
      {
        wrapper: queueWrapper,
      }
    );

    // Assertions
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Schedule' })).toBeInTheDocument();
    expect(container.querySelector('.usa-alert')).toBeNull();
    expect(container.querySelector('.cf-app-segment')).toBeInTheDocument();
    expect(container.querySelector('.schedule-veteran-details')).toBeInTheDocument();
    expect(screen.queryByText('will receive an email with connection information for the virtual hearing.')).toBeNull();
    // expect(scheduleVeteran).toMatchSnapshot();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays form validation errors when present and does not submit form', () => {
    // Render the scheduleVeteran component
    const {asFragment} = customRender(
      <ScheduleVeteran
        scheduledHearing={scheduledHearing}
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={amaAppeal.externalId}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          components: {
            forms: {
              assignHearing: {
                ...scheduleHearingDetails,
                hearingDay: null,
              },
            },
          },
        },
      }
    );

    // Run the test
    const scheduleVeteran = screen.getByRole('button', { name: 'Schedule' });
    expect(scheduleVeteran).toBeInTheDocument();

    fireEvent.click(scheduleVeteran);

    expect(patchSpy).toHaveBeenCalledTimes(0);
    expect(screen.getByText('Please select a hearing date')).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });
  test('Can handle backend validation errors for Legacy Appeals', () => {
    // Setup the test
    patchSpy.mockImplementationOnce(() => {
      throw defaultError;
    });

    // Render the scheduleVeteran component
    const {asFragment}=customRender(
      <ScheduleVeteran
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={legacyAppeal.externalId}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          components: {
            forms: {
              assignHearing: scheduleHearingDetails,
            },
          },
        },
      }
    );

    // Run the test
    const scheduleVeteran = screen.getByRole('button', { name: 'Schedule' });
    expect(scheduleVeteran).toBeInTheDocument();

    fireEvent.click(scheduleVeteran);

    expect(errorMessageSpy).toHaveBeenCalledWith({
      title: 'No Available Slots',
      detail:
        'Could not find any available slots for this regional office and hearing day combination. ' +
        'Please select a different date.',
    });

    expect(screen.getByText('No Available Slots')).toBeInTheDocument();
    expect(screen.getByText('Could not find any available slots for this regional office and hearing day combination. Please select a different date.')).toBeInTheDocument();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays error message title when present', () => {
    // Setup the test
    const titleError = {
      response: {
        body: {
          errors: [
            {
              title: 'Error',
              detail: 'message',
            },
          ],
        },
      },
    };

    patchSpy.mockImplementationOnce(() => {
      throw titleError;
    });

    // Render the scheduleVeteran component
    const {asFragment}=customRender(
      <ScheduleVeteran
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={legacyAppeal.externalId}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          components: {
            forms: {
              assignHearing: scheduleHearingDetails,
            },
          },
        },
      }
    );

    // Run the test
    const scheduleVeteran = screen.getByRole('button', { name: 'Schedule' });
    expect(scheduleVeteran).toBeInTheDocument();

    fireEvent.click(scheduleVeteran);

    expect(uiActions.showErrorMessage).toHaveBeenCalledWith(
      titleError.response.body.errors[0]
    );

    expect(screen.getByText('Error')).toBeInTheDocument();
    expect(screen.getByText('message')).toBeInTheDocument();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays email errors when present', async () => {
    // Setup the test
    const emailError = {
      response: {
        body: {
          errors: [
            {
              code: 1002,
              message: 'Validation Error: Email Address Validation Failed: Appellant email malformed',
            },
          ],
        },
      },
    };

    patchSpy.mockImplementationOnce(() => {
      throw emailError;
    });

    // Render the scheduleVeteran component
    const {asFragment}=customRender(
      <ScheduleVeteran
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={legacyAppeal.externalId}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          components: {
            forms: {
              assignHearing: scheduleHearingDetails,
            },
          },
        },
      }
    );

    // Run the test
    const scheduleVeteranInstance = screen.getByTestId('schedule-veteran-testid');

    let errorsTestAttribute = scheduleVeteranInstance.getAttribute('errors-test');
    const parsedTestAttribute = JSON.parse(errorsTestAttribute);
    expect(parsedTestAttribute).toEqual({})

    const scheduleVeteran = screen.getByRole('button', { name: 'Schedule' });
    expect(scheduleVeteran).toBeInTheDocument();

    fireEvent.click(scheduleVeteran);

    errorsTestAttribute = scheduleVeteranInstance.getAttribute('errors-test');
    const cleaned = errorsTestAttribute.replace(/\\"/g, '"');
    const parsedCleaned = JSON.parse(cleaned);
    expect(parsedCleaned).toEqual({
      appellantEmailAddress: ' Veteran email malformed',
    });

    expect(asFragment()).toMatchSnapshot();
  });

  test('Can handle backend validation errors for AMA Appeals', () => {
    // Setup the spy
    patchSpy.mockImplementationOnce(() => {
      throw defaultError;
    });

    // Render the scheduleVeteran component
    const {asFragment}=customRender(
      <ScheduleVeteran
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={amaAppeal.externalId}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          components: {
            forms: {
              assignHearing: scheduleHearingDetails,
            },
          },
        },
      }
    );

    // Run the test
    const scheduleVeteran = screen.getByRole('button', { name: 'Schedule' });
    expect(scheduleVeteran).toBeInTheDocument();

    fireEvent.click(scheduleVeteran);

    expect(cancelSpy).toHaveBeenCalledTimes(0);

    expect(uiActions.showErrorMessage).toHaveBeenCalledWith({
      title: 'No Hearing Day',
      detail:
        'Until April 1st hearing days for AMA appeals need to be created manually. ' +
        'Please contact the Caseflow Team for assistance.',
    });
    expect(asFragment()).toMatchSnapshot();
  });

  test('Can cancel the form', () => {
    // Render the scheduleVeteran component
    const {asFragment}=render(
      <ScheduleVeteran.WrappedComponent
        history={{ goBack: cancelSpy }}
        onChangeFormData={changeSpy}
        appeal={amaAppeal}
        taskId={scheduledHearing.taskId}
        setScheduledHearing={setScheduledHearingMock}
      />,
      {
        wrapper: queueWrapper,
      }
    );

    // Run the test
    const cancelButton = screen.getByRole('button', { name: 'Cancel' });
    expect(cancelButton).toBeInTheDocument();
    fireEvent.click(cancelButton);

    expect(cancelSpy).toHaveBeenCalledTimes(1);
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays virtual hearing alerts when present', async () => {
    // Setup the test
    jest.spyOn(utils, 'processAlerts');
    patchSpy.mockImplementationOnce(() => {
      return {
        body: {
          tasks: {
            ...scheduleVeteranResponse.body.tasks,
            alerts: [{ title: 'Success', detail: 'success' }],
          },
        },
      };
    });

    // Render the scheduleVeteran component
    const {asFragment}=customRender(
      <ScheduleVeteran {...scheduleVeteranProps} />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          components: {
            scheduledHearing,
            forms: {
              assignHearing: {
                ...scheduleHearingDetails,
                requestType: VIRTUAL_HEARING_LABEL,
                virtualHearing: virtualHearing.virtualHearing,
              },
            },
          },
        },
      }
    );

    // Run the test
    const scheduleVeteran = screen.getByRole('button', { name: 'Schedule' });
    expect(scheduleVeteran).toBeInTheDocument();

    fireEvent.click(scheduleVeteran);

    expect(patchSpy).toHaveBeenCalledWith(`/tasks/${scheduledHearing.taskId}`, {
      data: {
        task: {
          status: 'completed',
          business_payloads: {
            description: 'Update Task',
            values: {
              ...scheduleHearingDetails.apiFormattedValues,
              virtual_hearing_attributes: ApiUtil.convertToSnakeCase(
                omit(virtualHearing.virtualHearing, ['status'])
              ),
              email_recipients: ApiUtil.convertToSnakeCase(
                omit(virtualHearing.virtualHearing, ['status'])
              ),
              override_full_hearing_day_validation: false,
            },
          },
        },
      },
    }
  );

  expect(showSuccessMessageSpy).not.toHaveBeenCalled();
  await waitFor(() => {
    expect(utils.processAlerts).toHaveBeenCalled();
  });
    expect(asFragment()).toMatchSnapshot();
  });

  test('Can submit the form', async () => {
    // Setup the test
    patchSpy.mockReturnValue(scheduleVeteranResponse);
    const successMsg = {
      detail: (
        <p>
          To assign another veteran please use the "Schedule Veterans" link
          below. You can also use the hearings section below to view the hearing
          in new tab.
          <br />
          <br />
          <Link
            href={`/hearings/schedule/assign?regional_office_key=${
              scheduleHearingDetails.hearingDay.regionalOffice
            }`}
          >
            Back to Schedule Veterans
          </Link>
        </p>
      ),
      title: `You have successfully assigned ${
        amaAppeal.appellantFullName
      } to a ${VIDEO_HEARING_LABEL} hearing on ${formatDateStr(
        scheduleHearingDetails.hearingDay.hearingDate,
        'YYYY-MM-DD',
        'MM/DD/YYYY'
      )}.`,
    };

    // Render the scheduleVeteran component
    const {container, asFragment}=customRender(
      <ScheduleVeteran {...scheduleVeteranProps} />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          components: {
            scheduledHearing,
            forms: {
              assignHearing: scheduleHearingDetails,
            },
          },
        },
      }
    );

    // Run the test
    const scheduleVeteran = screen.getByRole('button', { name: 'Schedule' });
    expect(scheduleVeteran).toBeInTheDocument();

    fireEvent.click(scheduleVeteran);

    // Assertions
    expect(patchSpy).toHaveBeenCalledWith(`/tasks/${scheduledHearing.taskId}`, {
      data: {
        task: {
          status: 'completed',
          business_payloads: {
            description: 'Update Task',
            values: {
              ...scheduleHearingDetails.apiFormattedValues,
              email_recipients: {
                appellant_tz: 'America/New_York',
                representative_tz: 'America/New_York',
              },
              virtual_hearing_attributes: false,
              override_full_hearing_day_validation: false,
            },
          },
        },
      },
    });

    await waitFor(() => {
      expect(uiActions.showSuccessMessage).toHaveBeenCalledWith(successMsg);
    });
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays warning message for full hearing days', () => {
    // Render the scheduleVeteran component
    const {container, asFragment}=customRender(
      <ScheduleVeteran
        fetchScheduledHearings={fetchScheduledHearingsMock}
        scheduledHearing={scheduledHearing}
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={amaAppeal.externalId}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          components: {
            forms: {
              assignHearing: {
                ...scheduleHearingDetails,
                hearingDay: hearingDateOptions.filter(
                  (date) => date.value.filledSlots >= date.value.totalSlots
                )[0].value,
              },
            },
          },
        },
      }
    );

    // Assertions
    expect(screen.getByRole('alert')).toBeInTheDocument();
    expect(screen.getByText('You are about to schedule this Veteran on a full docket. Please verify before scheduling.')).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: 'This hearing day is full' })).toBeInTheDocument();
    expect(screen.getByTestId('schedule-veteran-form')).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays only an error when there is an open hearing on the selected appeal', () => {
    // Render the scheduleVeteran component
    const {asFragment}=customRender(
      <ScheduleVeteran
        appeals={appealsData}
        appealId={openHearingAppeal.externalId}
        scheduledHearing={scheduledHearing}
        error={{ detail: 'Open Hearing' }}
        history={{ goBack: cancelSpy }}
        onChangeFormData={changeSpy}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          components: {
            forms: {
              assignHearing: scheduleHearingDetails,
            },
          },
        },
      }
    );

    // Assertions
    expect(screen.queryByTestId('schedule-veteran-form')).toBeNull();
    expect(screen.getByRole('alert')).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: 'Open Hearing' })).toBeInTheDocument();
    expect(screen.getByText('This appeal has an open hearing on 08/07/2020. You cannot schedule another hearing.')).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays virtual hearing form details for virtual hearings', () => {
    // Render the scheduleVeteran component
    const {asFragment}=customRender(
      <ScheduleVeteran
        fetchScheduledHearings={fetchScheduledHearingsMock}
        scheduledHearing={scheduledHearing}
        onChangeFormData={changeSpy}
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={defaultHearing}
      />,
      {
        wrapper: queueWrapper,
        wrapper: queueWrapper,
      }
    );

    // Assertions
    // RepresentativeSection present
    expect(screen.getByText('The Veteran does not have a representative recorded in VBMS')).toBeInTheDocument();

    // AppellantSection present
    expect(screen.getByRole('combobox', {name: 'Veteran Timezone Required'})).toBeInTheDocument();
    expect(screen.getByRole('textbox', {name: 'Veteran Email (for these notifications only) Required'})).toBeInTheDocument();

    // AppSegment present
    expect(screen.getByText('When you schedule the hearing, the Veteran and Judge will receive an email with connection information for the virtual hearing.')).toBeInTheDocument();

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
         wrapper: Wrapper,
          wrapperProps: {
            components: {
              forms: {
                assignHearing: {
                  ...scheduleHearingDetails,
                  requestType: VIRTUAL_HEARING_LABEL,
                  virtualHearing: virtualHearing.virtualHearing,
                },
              },
            },
          },
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

      // Assertions
      expect(screen.getByRole('combobox', {name: 'Hearing Type'})).toBeInTheDocument();
      expect(screen.getByTestId('schedule-veteran-form')).toBeInTheDocument();
      expect(screen.getAllByText('Virtual')[0]).toBeInTheDocument();
      expect(asFragment()).toMatchSnapshot();
  });
});
