import React from 'react';
import { mount } from 'enzyme';

import { VIRTUAL_HEARING_LABEL } from 'app/hearings/constants';
import { ScheduleVeteranForm } from 'app/hearings/components/ScheduleVeteranForm';
import { ReadOnly } from 'app/hearings/components/details/ReadOnly';
import { amaAppeal, defaultHearing, virtualHearing } from 'test/data';
import { generateAmaTask } from 'test/data/tasks';
import { queueWrapper } from 'test/data/stores/queueStore';
import HearingTypeDropdown from 'app/hearings/components/details/HearingTypeDropdown';
import {
  HearingDateDropdown,
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
} from 'app/components/DataDropdowns';
import { AppealInformation } from 'app/hearings/components/scheduleHearing/AppealInformation';
import { AddressLine } from 'app/hearings/components/details/Address';
import { AppellantSection } from 'app/hearings/components/VirtualHearings/AppellantSection';
import { RepresentativeSection } from 'app/hearings/components/VirtualHearings/RepresentativeSection';
import { Timezone } from 'app/hearings/components/VirtualHearings/Timezone';
import { UnscheduledNotes } from 'app/hearings/components/UnscheduledNotes';
import { HearingTime } from 'app/hearings/components/modalForms/HearingTime';
import { ReadOnlyHearingTimeWithZone } from 'app/hearings/components/modalForms/ReadOnlyHearingTimeWithZone';

// Set the spies
const changeSpy = jest.fn();
const submitSpy = jest.fn();
const cancelSpy = jest.fn();

describe('ScheduleVeteranForm', () => {
  test('Matches snapshot with default props', () => {
    // Render the address component
    const scheduleVeteran = mount(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    // Assertions
    expect(scheduleVeteran.find(HearingTypeDropdown)).toHaveLength(1);
    expect(scheduleVeteran.find(RegionalOfficeDropdown)).toHaveLength(1);
    expect(scheduleVeteran.find(AppealInformation)).toHaveLength(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays hearing form when regional office is selected', () => {
    // Render the address component
    const scheduleVeteran = mount(
      <ScheduleVeteranForm
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
        wrappingComponent: queueWrapper,
      }
    );

    // Assertions
    expect(scheduleVeteran.find(AppealInformation)).toHaveLength(1);
    expect(scheduleVeteran.find(AppealHearingLocationsDropdown)).toHaveLength(1);
    expect(scheduleVeteran.find(HearingDateDropdown)).toHaveLength(1);

    expect(scheduleVeteran.find(AppellantSection)).toHaveLength(0);
    expect(scheduleVeteran.find(RepresentativeSection)).toHaveLength(0);

    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays Virtual Hearing form fields when type is changed to Virtual', () => {
    // Render the address component
    const scheduleVeteran = mount(
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
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    // CHeck for virtual hearing fields
    expect(scheduleVeteran.find(AppellantSection)).toHaveLength(1);
    expect(scheduleVeteran.find(RepresentativeSection)).toHaveLength(1);

    // Ensure the Veteran address is not displayed
    expect(scheduleVeteran.find(ReadOnly).first().
      find(AddressLine)).toHaveLength(0);

    // Ensure Video-only fields are not displayed
    expect(scheduleVeteran.find(AppealHearingLocationsDropdown)).toHaveLength(0);
    expect(scheduleVeteran.find('[label="Hearing Location"]').text()).toEqual('Hearing LocationVirtual');

    // Ensure Timezone fields display when scheduling virtual
    expect(scheduleVeteran.find(Timezone)).toHaveLength(2);

    // Change the regional office to Central
    scheduleVeteran.setProps({
      hearing: {
        ...defaultHearing,
        regionalOffice: 'C',
        virtualHearing: virtualHearing.virtualHearing
      }
    });

    // Make sure the timezones display after changing to Central
    expect(scheduleVeteran.find(Timezone)).toHaveLength(2);

    expect(scheduleVeteran.find(AppealInformation)).toHaveLength(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays error messages when errors are present', () => {
    // Setup the test
    const error = 'Please select hearing day';

    // Render the address component
    const scheduleVeteran = mount(
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
        wrappingComponent: queueWrapper,
      }
    );

    // Assertions
    expect(scheduleVeteran.find(AppealInformation)).toHaveLength(1);
    expect(scheduleVeteran.find(HearingDateDropdown).prop('errorMessage')).toEqual(error);
    expect(scheduleVeteran).toMatchSnapshot();
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

    const scheduleVeteran = mount(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={defaultHearing}
        hearingTask={parentHearingTask}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    expect(scheduleVeteran.find(UnscheduledNotes)).toHaveLength(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('RO dropdown includes Virtual Hearings as option is type is selected as Virtual', () => {
    const scheduleVeteran = mount(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={defaultHearing}
        virtual
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    expect(scheduleVeteran.find(RegionalOfficeDropdown)).toHaveLength(1);
    expect(scheduleVeteran.find(RegionalOfficeDropdown).
      prop('excludeVirtualHearingsOption')).toEqual(false);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays ReadOnlyHearingTimeWithZone when video is selected and halfDay is true', () => {
    const hearing = {
      ...defaultHearing,
      regionalOffice: defaultHearing.regionalOfficeKey,
      hearingDay: {
        hearingId: 1,
        readableRequestType: 'Video',
        beginsAt: '2021-07-29T11:30:00-04:00',
        halfDay: true,
        timezone: 'America/Los_Angeles'
      }
    };
    const scheduleVeteran = mount(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={hearing}
        virtual={false}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    expect(scheduleVeteran.find(HearingTime)).toHaveLength(0);
    expect(scheduleVeteran.find(ReadOnlyHearingTimeWithZone)).toHaveLength(1);
    expect(
      scheduleVeteran.find(ReadOnlyHearingTimeWithZone).find(ReadOnly).
        prop('text')
    ).toEqual('8:30 AM Pacific / 11:30 AM Eastern');
    expect(scheduleVeteran).toMatchSnapshot();
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
        timezone: 'America/Los_Angeles'
      }
    };
    const scheduleVeteran = mount(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={hearing}
        virtual={false}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    expect(scheduleVeteran.find(HearingTime)).toHaveLength(1);
    expect(scheduleVeteran.find(ReadOnlyHearingTimeWithZone)).toHaveLength(0);
    expect(scheduleVeteran).toMatchSnapshot();
  });
});
