import React from 'react';

import { TimeSlotButton } from 'app/hearings/components/scheduleHearing/TimeSlotButton';
import { render } from '@testing-library/react';
import { roTimezones, formatTimeSlotLabel } from 'app/hearings/utils';

const time = '08:15';
const issueCount = 2;
const poaName = 'Something';

let roTimezone = '';
let expectedTime = '';

describe('TimeSlotButton', () => {
  beforeEach(() => {

    roTimezone = roTimezones()[0];
    expectedTime = formatTimeSlotLabel(time, roTimezone);
  });

  test('Matches snapshot with default props', () => {
    // Run the test
    const button = render(
      <TimeSlotButton roTimezone={roTimezone} hearingTime={time} />
    );

    // Assertions
    expect(button.getByRole('button')).toHaveTextContent(expectedTime);
    expect(document.getElementsByClassName('time-slot-details')).toHaveLength(0);
    expect(document.getElementsByClassName('time-slot-arrow')).toHaveLength(1);
    expect(document.getElementsByClassName('time-slot-button')).toHaveLength(1);
    expect(button).toMatchSnapshot();
  });

  test('Applies selected styling when selected is true', () => {
    // Run the test
    const button = render(
      <TimeSlotButton roTimezone={roTimezone} hearingTime={time} selected />
    );

    // Assertions
    expect(button.getByRole('button')).toHaveTextContent(expectedTime);
    expect(document.getElementsByClassName('time-slot-button-selected')).toHaveLength(1);
    expect(button).toMatchSnapshot();
  });

  test('Displays full time details and is disabled when full is true', () => {
    // Run the test
    const button = render(
      <TimeSlotButton roTimezone={roTimezone} hearingTime={time} full issueCount={issueCount} poaName={poaName} />
    );

    // Assertions
    expect(button.getByRole('button')).toHaveTextContent(expectedTime);
    expect(document.getElementsByClassName('time-slot-details')[0]).toHaveTextContent(issueCount);
    expect(document.getElementsByClassName('time-slot-details')[0]).toHaveTextContent(poaName);
    expect(document.getElementsByClassName('time-slot-button-full')).toHaveLength(1);
    expect(button).toMatchSnapshot();
  });
})
;
