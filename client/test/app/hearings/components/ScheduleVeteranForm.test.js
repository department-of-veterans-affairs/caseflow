import React from 'react';
import { shallow } from 'enzyme';

import { ScheduleVeteranForm } from 'app/hearings/components/ScheduleVeteranForm';
import { ReadOnly } from 'app/hearings/components/details/ReadOnly';
import { amaAppeal, defaultHearing } from 'test/data';
import { queueWrapper, queueStore } from 'test/data/stores/queueStore';
import HearingTypeDropdown from 'app/hearings/components/details/HearingTypeDropdown';
import {
  HearingDateDropdown,
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
} from 'app/components/DataDropdowns';
import { AddressLine } from 'app/hearings/components/details/Address';
import { HearingTime } from 'app/hearings/components/modalForms/HearingTime';
import Button from 'app/components/Button';

// Set the spies
const changeSpy = jest.fn();
const submitSpy = jest.fn();
const cancelSpy = jest.fn();

describe('ScheduleVeteranForm', () => {
  test('Matches snapshot with default props', () => {
    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={amaAppeal}
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: { store: queueStore },
      }
    );

    // Assertions
    expect(scheduleVeteran.find(Button).first().
      prop('name')).toEqual('Cancel');
    expect(scheduleVeteran.find(Button).at(1).
      prop('name')).toEqual('Schedule');
    expect(scheduleVeteran.find(ReadOnly)).toHaveLength(1);
    expect(scheduleVeteran.find(ReadOnly).prop('text')).toMatchObject(<AddressLine />);
    expect(scheduleVeteran.find(HearingTypeDropdown)).toHaveLength(1);
    expect(scheduleVeteran.find(RegionalOfficeDropdown)).toHaveLength(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays hearing form when regional office is selected', () => {
    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={{
          ...amaAppeal,
          regionalOffice: defaultHearing.regionalOfficeKey,
        }}
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: { store: queueStore },
      }
    );

    // Assertions
    expect(scheduleVeteran.find(AppealHearingLocationsDropdown)).toHaveLength(1);
    expect(scheduleVeteran.find(HearingDateDropdown)).toHaveLength(1);
    expect(scheduleVeteran.find(HearingTime)).toHaveLength(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Can cancel the form', () => {
    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={{
          ...amaAppeal,
          regionalOffice: defaultHearing.regionalOfficeKey,
        }}
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: { store: queueStore },
      }
    );

    // Run the test
    scheduleVeteran.find(Button).first().
      simulate('click');

    // Assertions
    expect(cancelSpy).toHaveBeenCalledTimes(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });
  test('Can submit the form', () => {
    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={{
          ...amaAppeal,
          regionalOffice: defaultHearing.regionalOfficeKey,
        }}
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: { store: queueStore },
      }
    );

    // Run the test
    scheduleVeteran.find(Button).at(1).
      simulate('click');

    // Assertions
    expect(submitSpy).toHaveBeenCalledTimes(1);
    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays Virtual Hearing form fields when type is changed to Virtual', () => {
    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={{
          ...amaAppeal,
          regionalOffice: defaultHearing.regionalOfficeKey,
        }}
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: { store: queueStore },
      }
    );

    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Can toggle back to Video', () => {
    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={{
          ...amaAppeal,
          regionalOffice: defaultHearing.regionalOfficeKey,
        }}
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: { store: queueStore },
      }
    );

    expect(scheduleVeteran).toMatchSnapshot();
  });

  test('Displays error messages when errors are present', () => {
    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteranForm
        goBack={cancelSpy}
        submit={submitSpy}
        onChange={changeSpy}
        appeal={{
          ...amaAppeal,
          regionalOffice: defaultHearing.regionalOfficeKey,
        }}
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: { store: queueStore },
      }
    );

    expect(scheduleVeteran).toMatchSnapshot();
  });
});
