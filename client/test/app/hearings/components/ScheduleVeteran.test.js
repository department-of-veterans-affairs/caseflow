import React from 'react';
import { shallow, mount } from 'enzyme';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import COPY from 'COPY';
import { ScheduleVeteran } from 'app/hearings/components/ScheduleVeteran';
import {
  amaAppeal,
  defaultHearing,
  scheduleHearingDetails,
  virtualHearing,
  hearingDateOptions,
} from 'test/data';
import { queueWrapper } from 'test/data/stores/queueStore';
import Button from 'app/components/Button';
import { Link } from 'react-router-dom';
import { formatDateStr } from 'app/util/DateUtil';
import { HEARING_REQUEST_TYPES } from 'app/hearings/constants';
import Alert from 'app/components/Alert';
import { AppellantSection } from 'app/hearings/components/VirtualHearings/AppellantSection';
import { RepresentativeSection } from 'app/hearings/components/VirtualHearings/RepresentativeSection';
import { ScheduleVeteranForm } from 'app/hearings/components/ScheduleVeteranForm';

// Set the spies
const changeSpy = jest.fn();
const cancelSpy = jest.fn();
const submitSpy = jest.fn();
const error = 'Error';

describe('ScheduleVeteran', () => {
  test('Matches snapshot with default props', () => {
    // Render the address component
    const scheduleVeteran = mount(
      <ScheduleVeteran
        goBack={cancelSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    // Assertions
    expect(scheduleVeteran.find(Button).first().
      prop('name')).toEqual('Cancel');
    expect(scheduleVeteran.find(Button).at(1).
      prop('name')).toEqual('Schedule');
    expect(scheduleVeteran.find(Alert)).toHaveLength(0);
    expect(scheduleVeteran.find(AppSegment)).toHaveLength(1);
    expect(scheduleVeteran.find(ScheduleVeteranForm)).toHaveLength(1);
    expect(scheduleVeteran.find(AppSegment).text()).not.toContain(COPY.SCHEDULE_VETERAN_DIRECT_TO_VIRTUAL_HELPER_LABEL);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays form validation errors when present and does not submit form', () => {
    // Setup the test
    const errors = {
      hearingLocation: null,
      scheduledTimeString: null,
      regionalOffice: null,
      hearingDay: 'Please select a hearing date'
    };

    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteran
        history={{ goBack: cancelSpy }}
        requestPatch={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        assignHearingForm={{
          ...scheduleHearingDetails,
          hearingDay: null
        }}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    // Run the test
    scheduleVeteran.find(Button).at(1).
      simulate('click');
    expect(submitSpy).toHaveBeenCalledTimes(0);
    expect(scheduleVeteran.find(ScheduleVeteranForm).prop('errors')).toEqual(errors);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Can handle backend validation errors for Legacy Appeals', () => {
    // Setup the spy
    const errorMessageSpy = jest.fn();
    const errorSpy = jest.fn(() => {
      throw error;
    });

    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteran
        showErrorMessage={errorMessageSpy}
        history={{ goBack: cancelSpy }}
        requestPatch={errorSpy}
        onChange={changeSpy}
        appeal={{
          ...amaAppeal,
          isLegacyAppeal: true
        }}
        assignHearingForm={scheduleHearingDetails}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    // Run the test
    scheduleVeteran.find(Button).at(1).
      simulate('click');
    expect(cancelSpy).toHaveBeenCalledTimes(0);
    expect(errorMessageSpy).toHaveBeenCalledWith({
      title: 'No Available Slots',
      detail:
        'Could not find any available slots for this regional office and hearing day combination. ' +
        'Please select a different date.',
    });
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Can handle backend validation errors for AMA Appeals', () => {
    // Setup the spy
    const errorMessageSpy = jest.fn();
    const errorSpy = jest.fn(() => {
      throw error;
    });

    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteran
        showErrorMessage={errorMessageSpy}
        history={{ goBack: cancelSpy }}
        requestPatch={errorSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        assignHearingForm={scheduleHearingDetails}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    // Run the test
    scheduleVeteran.find(Button).at(1).
      simulate('click');
    expect(cancelSpy).toHaveBeenCalledTimes(0);
    expect(errorMessageSpy).toHaveBeenCalledWith({
      title: 'No Hearing Day',
      detail:
        'Until April 1st hearing days for AMA appeals need to be created manually. ' +
        'Please contact the Caseflow Team for assistance.',
    });
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Can cancel the form', () => {
    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteran
        history={{ goBack: cancelSpy }}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    // Run the test
    scheduleVeteran.
      find(Button).
      first().
      simulate('click');

    // Assertions
    expect(cancelSpy).toHaveBeenCalledTimes(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Can submit the form', () => {
    // Setup the test
    const scheduleHearingTask = { taskId: '123' };
    const successMsg = {
      detail: (
        <p>
          To assign another veteran please use the "Schedule Veterans" link
          below. You can also use the hearings section below to view the hearing
          in new tab.
          <br />
          <br />
          <Link to={`/hearings/schedule/assign?regional_office_key=${scheduleHearingDetails.hearingDay.regionalOffice}`}>
            Back to Schedule Veterans
          </Link>
        </p>
      ),
      title: `You have successfully assigned ${
        amaAppeal.appellantFullName
      } to a ${HEARING_REQUEST_TYPES.V} hearing on ${formatDateStr(
        scheduleHearingDetails.hearingDay.hearingDate,
        'YYYY-MM-DD',
        'MM/DD/YYYY'
      )}.`,
    };

    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteran
        scheduleHearingTask={scheduleHearingTask}
        history={{ goBack: cancelSpy }}
        requestPatch={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        assignHearingForm={scheduleHearingDetails}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    // Run the test
    scheduleVeteran.find(Button).at(1).
      simulate('click');

    // Assertions
    expect(submitSpy).toHaveBeenCalledWith(
      `/tasks/${scheduleHearingTask.taskId}`,
      {
        data: {
          task: {
            status: 'completed',
            business_payloads: {
              description: 'Update Task',
              values: {
                ...scheduleHearingDetails.apiFormattedValues,
                override_full_hearing_day_validation: false,
              },
            },
          },
        },
      },
      successMsg
    );
    expect(cancelSpy).toHaveBeenCalledTimes(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays warning message for full hearing days', () => {
    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteran
        history={{ goBack: cancelSpy }}
        requestPatch={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        assignHearingForm={{
          ...scheduleHearingDetails,
          hearingDay: hearingDateOptions.filter((date) => date.value.filledSlots >= date.value.totalSlots)[0].value
        }}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    expect(scheduleVeteran.find(Alert)).toHaveLength(1);
    expect(scheduleVeteran.find(ScheduleVeteranForm)).toHaveLength(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays only an error when there is an open hearing on the selected appeal', () => {
    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteran
        error={{ detail: 'Open Hearing' }}
        history={{ goBack: cancelSpy }}
        requestPatch={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        assignHearingForm={scheduleHearingDetails}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    // Assertions
    expect(scheduleVeteran.find(ScheduleVeteranForm)).toHaveLength(0);
    expect(scheduleVeteran.find(Alert)).toHaveLength(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays virtual hearing form details for virtual hearings', () => {
    // Render the address component
    const scheduleVeteran = mount(
      <ScheduleVeteran
        onChangeFormData={changeSpy}
        goBack={cancelSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={defaultHearing}
        assignHearingForm={{
          ...scheduleHearingDetails,
          virtualHearing: virtualHearing.virtualHearing
        }}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    // Assertions
    expect(scheduleVeteran.find(RepresentativeSection)).toHaveLength(1);
    expect(scheduleVeteran.find(AppellantSection)).toHaveLength(1);
    expect(scheduleVeteran.find(AppSegment).text()).toContain(COPY.SCHEDULE_VETERAN_DIRECT_TO_VIRTUAL_HELPER_LABEL);
    expect(scheduleVeteran).toMatchSnapshot();
  });
});
