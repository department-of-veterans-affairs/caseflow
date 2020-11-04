import React from 'react';
import { mount } from 'enzyme';

import { VIRTUAL_HEARING_LABEL } from 'app/hearings/constants';
import { ScheduleVeteranForm } from 'app/hearings/components/ScheduleVeteranForm';
import { SearchableDropdown } from 'app/components/SearchableDropdown';
import { ReadOnly } from 'app/hearings/components/details/ReadOnly';
import { amaAppeal, defaultHearing, legacyAppealForTravelBoard, virtualHearing } from 'test/data';
import { queueWrapper } from 'test/data/stores/queueStore';
import HearingTypeDropdown from 'app/hearings/components/details/HearingTypeDropdown';
import {
  HearingDateDropdown,
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
} from 'app/components/DataDropdowns';
import { AddressLine } from 'app/hearings/components/details/Address';
import { HearingTime } from 'app/hearings/components/modalForms/HearingTime';
import { AppellantSection } from 'app/hearings/components/VirtualHearings/AppellantSection';
import { RepresentativeSection } from 'app/hearings/components/VirtualHearings/RepresentativeSection';
import { Timezone } from 'app/hearings/components/VirtualHearings/Timezone';

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
    expect(
      scheduleVeteran.find(ReadOnly).first().prop('text').props
    ).toMatchObject(
      {
        addressLine1: amaAppeal.appellantAddress.address_line_1,
        addressCity: amaAppeal.appellantAddress.city,
        addressZip: amaAppeal.appellantAddress.zip,
        addressState: amaAppeal.appellantAddress.state
      }
    );
    expect(scheduleVeteran.find(HearingTypeDropdown)).toHaveLength(1);
    expect(scheduleVeteran.find(RegionalOfficeDropdown)).toHaveLength(1);
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
    expect(scheduleVeteran.find(AppealHearingLocationsDropdown)).toHaveLength(1);
    expect(scheduleVeteran.find(HearingDateDropdown)).toHaveLength(1);
    expect(scheduleVeteran.find(HearingTime)).toHaveLength(1);
    expect(scheduleVeteran.find(AddressLine)).toHaveLength(1);

    expect(scheduleVeteran.find(AppellantSection)).toHaveLength(0);
    expect(scheduleVeteran.find(RepresentativeSection)).toHaveLength(0);

    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays Virtual Hearing form fields when type is changed to Virtual', () => {
    // Render the address component
    const scheduleVeteran = mount(
      <ScheduleVeteranForm
        virtual
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={{
          ...amaAppeal,
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
    expect(scheduleVeteran.find(ReadOnly).first().
      text()).toEqual('Hearing LocationVirtual');

    // Make sure there are no timezones for non-Central ROs
    expect(scheduleVeteran.find(Timezone)).toHaveLength(0);

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
    expect(scheduleVeteran.find(HearingDateDropdown).prop('errorMessage')).toEqual(error);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Auto-selects virtual if a virtual hearing was requested', () => {
    const hearing = {
      ...defaultHearing,
      virtualHearing: { status: 'pending' }, // Simulate an onChange event
      regionalOffice: defaultHearing.regionalOfficeKey,
    };
    const scheduleVeteran = mount(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={{
          ...legacyAppealForTravelBoard,
          regionalOffice: defaultHearing.regionalOfficeKey,
          readableHearingRequestType: VIRTUAL_HEARING_LABEL,
        }}
        hearing={hearing}
        virtual={false}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    expect(
      scheduleVeteran.
        find(HearingTypeDropdown).
        find(SearchableDropdown).
        prop('value')
    ).toEqual({ label: VIRTUAL_HEARING_LABEL, value: true });
    expect(scheduleVeteran).toMatchSnapshot();
  });
});
