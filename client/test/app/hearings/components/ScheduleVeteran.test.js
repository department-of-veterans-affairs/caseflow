/* eslint-disable max-lines */
import React from 'react';
import { mount } from 'enzyme';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { omit } from 'lodash';

import COPY from 'COPY';
import ScheduleVeteran from 'app/hearings/components/ScheduleVeteran';
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
} from 'test/data';
import { queueWrapper, appealsData } from 'test/data/stores/queueStore';
import Button from 'app/components/Button';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { formatDateStr } from 'app/util/DateUtil';
import Alert from 'app/components/Alert';
import { AppellantSection } from 'app/hearings/components/VirtualHearings/AppellantSection';
import { RepresentativeSection } from 'app/hearings/components/VirtualHearings/RepresentativeSection';
import { ScheduleVeteranForm } from 'app/hearings/components/ScheduleVeteranForm';
import ApiUtil from 'app/util/ApiUtil';

import * as uiActions from 'app/queue/uiReducer/uiActions';

import { VIDEO_HEARING_LABEL, VIRTUAL_HEARING_LABEL } from 'app/hearings/constants';

jest.mock('app/queue/uiReducer/uiActions');
import * as utils from 'app/hearings/utils';

// Set the spies
const changeSpy = jest.fn();
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

let patchSpy;
const setState = jest.fn();
const useStateMock = (initState) => [initState, setState];
const setScheduledHearingMock = jest.fn();
const fetchScheduledHearingsMock = jest.fn();

const scheduleVeteranProps = {
  userCanCollectVideoCentralEmails: true,
  showSuccessMessage: jest.fn(),
  onChangeFormData: changeSpy,
  appeals: appealsData,
  appealId: amaAppeal.externalId,
  taskId: scheduledHearing.taskId,
  setScheduledHearing: setScheduledHearingMock,
  fetchScheduledHearings: fetchScheduledHearingsMock,
};

describe('ScheduleVeteran', () => {
  beforeEach(() => {
    jest.
      spyOn(document, 'getElementById').
      mockReturnValue({ scrollIntoView: jest.fn() });
    jest.spyOn(utils, 'processAlerts');
    patchSpy = jest.spyOn(ApiUtil, 'patch');
    jest.spyOn(React, 'useState').mockImplementation(useStateMock);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('Matches snapshot with default props', () => {
    // Render the scheduleVeteran component
    const scheduleVeteran = mount(
      <ScheduleVeteran
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={amaAppeal.externalId}
        hearing={defaultHearing}
        scheduledHearing={scheduledHearing}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    // Assertions
    expect(
      scheduleVeteran.
        find(Button).
        first().
        prop('name')
    ).toEqual('Cancel');
    expect(
      scheduleVeteran.
        find(Button).
        at(1).
        prop('name')
    ).toEqual('Schedule');
    expect(scheduleVeteran.find(Alert)).toHaveLength(0);
    expect(scheduleVeteran.find(AppSegment)).toHaveLength(1);
    expect(scheduleVeteran.find(ScheduleVeteranForm)).toHaveLength(1);
    expect(scheduleVeteran.find(AppSegment).text()).not.toContain(
      'will receive an email with connection information for the virtual hearing.'
    );
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays form validation errors when present and does not submit form', async () => {
    // Setup the test
    const errors = {
      hearingLocation: null,
      scheduledTimeString: null,
      regionalOffice: null,
      hearingDay: 'Please select a hearing date',
    };

    // Render the scheduleVeteran component
    const scheduleVeteran = mount(
      <ScheduleVeteran
        scheduledHearing={scheduledHearing}
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={amaAppeal.externalId}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: {
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
    scheduleVeteran.
      find(Button).
      at(1).
      find('button').
      simulate('click');
    expect(patchSpy).toHaveBeenCalledTimes(0);
    expect(scheduleVeteran.find(ScheduleVeteranForm).prop('errors')).toEqual(
      errors
    );
    expect(scheduleVeteran).toMatchSnapshot();
  });
  test('Can handle backend validation errors for Legacy Appeals', () => {
    // Setup the test
    patchSpy.mockImplementationOnce(() => {
      throw defaultError;
    });

    // Render the scheduleVeteran component
    const scheduleVeteran = mount(
      <ScheduleVeteran
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={legacyAppeal.externalId}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: {
          components: {
            forms: {
              assignHearing: scheduleHearingDetails,
            },
          },
        },
      }
    );

    // Run the test
    scheduleVeteran.
      find(Button).
      at(1).
      find('button').
      simulate('click');
    expect(uiActions.showErrorMessage).toHaveBeenCalledWith({
      title: 'No Available Slots',
      detail:
        'Could not find any available slots for this regional office and hearing day combination. ' +
        'Please select a different date.',
    });
    expect(scheduleVeteran).toMatchSnapshot();
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
    const scheduleVeteran = mount(
      <ScheduleVeteran
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={legacyAppeal.externalId}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: {
          components: {
            forms: {
              assignHearing: scheduleHearingDetails,
            },
          },
        },
      }
    );

    // Run the test
    scheduleVeteran.
      find(Button).
      at(1).
      find('button').
      simulate('click');
    expect(uiActions.showErrorMessage).toHaveBeenCalledWith(
      titleError.response.body.errors[0]
    );
    expect(scheduleVeteran).toMatchSnapshot();
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
    const scheduleVeteran = mount(
      <ScheduleVeteran
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={legacyAppeal.externalId}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: {
          components: {
            forms: {
              assignHearing: scheduleHearingDetails,
            },
          },
        },
      }
    );

    // Run the test
    expect(scheduleVeteran.find(ScheduleVeteranForm).prop('errors')).toEqual(
      {}
    );

    await scheduleVeteran.
      find(Button).
      at(1).
      find('button').
      simulate('click');
    expect(scheduleVeteran.find(ScheduleVeteranForm).prop('errors')).toEqual({
      appellantEmail: ' Veteran email malformed',
    });
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Can handle backend validation errors for AMA Appeals', () => {
    // Setup the spy
    patchSpy.mockImplementationOnce(() => {
      throw defaultError;
    });

    // Render the scheduleVeteran component
    const scheduleVeteran = mount(
      <ScheduleVeteran
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={amaAppeal.externalId}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: {
          components: {
            forms: {
              assignHearing: scheduleHearingDetails,
            },
          },
        },
      }
    );

    // Run the test
    scheduleVeteran.
      find(Button).
      at(1).
      find('button').
      simulate('click');
    expect(cancelSpy).toHaveBeenCalledTimes(0);
    expect(uiActions.showErrorMessage).toHaveBeenCalledWith({
      title: 'No Hearing Day',
      detail:
        'Until April 1st hearing days for AMA appeals need to be created manually. ' +
        'Please contact the Caseflow Team for assistance.',
    });
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Can cancel the form', async () => {
    // Render the scheduleVeteran component
    const scheduleVeteran = mount(
      <ScheduleVeteran.WrappedComponent
        history={{ goBack: cancelSpy }}
        onChangeFormData={changeSpy}
        appeal={amaAppeal}
        taskId={scheduledHearing.taskId}
        setScheduledHearing={setScheduledHearingMock}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    // Run the test
    await scheduleVeteran.
      find(Button).
      first().
      find('button').
      simulate('click');

    // Assertions
    expect(cancelSpy).toHaveBeenCalledTimes(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays virtual hearing alerts when present', async () => {
    // Setup the test
    patchSpy.mockReturnValueOnce({
      body: {
        tasks: {
          ...scheduleVeteranResponse.body.tasks,
          alerts: [{ title: 'Success', detail: 'success' }],
        },
      },
    });

    // Render the scheduleVeteran component
    const scheduleVeteran = mount(
      <ScheduleVeteran {...scheduleVeteranProps} />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: {
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
    await scheduleVeteran.
      find(Button).
      at(1).
      find('button').
      simulate('click');

    // Assertions
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
    });
    expect(uiActions.showSuccessMessage).not.toHaveBeenCalled();
    expect(utils.processAlerts).toHaveBeenCalled();
    expect(scheduleVeteran).toMatchSnapshot();
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
    const scheduleVeteran = mount(
      <ScheduleVeteran {...scheduleVeteranProps} />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: {
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
    await scheduleVeteran.
      find(Button).
      at(1).
      find('button').
      simulate('click');

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
    expect(uiActions.showSuccessMessage).toHaveBeenCalledWith(successMsg);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays warning message for full hearing days', () => {
    // Render the scheduleVeteran component
    const scheduleVeteran = mount(
      <ScheduleVeteran
        fetchScheduledHearings={fetchScheduledHearingsMock}
        scheduledHearing={scheduledHearing}
        onChangeFormData={changeSpy}
        appeals={appealsData}
        appealId={amaAppeal.externalId}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: {
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

    expect(scheduleVeteran.find(Alert)).toHaveLength(1);
    expect(scheduleVeteran.find(ScheduleVeteranForm)).toHaveLength(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays only an error when there is an open hearing on the selected appeal', () => {
    // Render the scheduleVeteran component
    const scheduleVeteran = mount(
      <ScheduleVeteran
        appeals={appealsData}
        appealId={openHearingAppeal.externalId}
        scheduledHearing={scheduledHearing}
        error={{ detail: 'Open Hearing' }}
        history={{ goBack: cancelSpy }}
        onChangeFormData={changeSpy}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: {
          components: {
            forms: {
              assignHearing: scheduleHearingDetails,
            },
          },
        },
      }
    );

    // Assertions
    expect(scheduleVeteran.find(ScheduleVeteranForm)).toHaveLength(0);
    expect(scheduleVeteran.find(Alert)).toHaveLength(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays virtual hearing form details for virtual hearings', () => {
    // Render the scheduleVeteran component
    const scheduleVeteran = mount(
      <ScheduleVeteran
        fetchScheduledHearings={fetchScheduledHearingsMock}
        scheduledHearing={scheduledHearing}
        onChangeFormData={changeSpy}
        goBack={cancelSpy}
        appeals={appealsData}
        appealId={amaAppeal.externalId}
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: {
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

    // Assertions
    expect(scheduleVeteran.find(RepresentativeSection)).toHaveLength(1);
    expect(scheduleVeteran.find(AppellantSection)).toHaveLength(1);
    expect(scheduleVeteran.find(AppSegment).text()).toContain(
      'will receive an email with connection information for the virtual hearing.'
    );
    expect(scheduleVeteran).toMatchSnapshot();
  });
});
