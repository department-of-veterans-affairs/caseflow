import React from 'react';
import { shallow } from 'enzyme';

import { ScheduleVeteran } from 'app/hearings/components/ScheduleVeteran';
import { amaAppeal, defaultHearing } from 'test/data';
import { queueWrapper, queueStore } from 'test/data/stores/queueStore';

// Set the spies
const changeSpy = jest.fn();
const submitSpy = jest.fn();
const cancelSpy = jest.fn();

describe('ScheduleVeteran', () => {
  test('Matches snapshot with default props', () => {
    // Render the address component
    const scheduleVeteran = shallow(
      <ScheduleVeteran
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
    expect(scheduleVeteran).toMatchSnapshot();
  });
});
