import React from 'react';

import { TimeSlot } from 'app/hearings/components/scheduleHearing/TimeSlot';
import { render, fireEvent, screen } from '@testing-library/react';
import { roTimezones, setTimeSlots, formatTimeSlotLabel } from 'app/hearings/utils';

const time = '08:30';
const time2 = '09:30';
const emptyHearings = [];

// Create the mock functions
const onChange = jest.fn();
const fetchScheduledHearings = jest.fn();

let roTimezone = '';
let slotCount = '';

describe('TimeSlot', () => {
  beforeEach(() => {

    roTimezone = roTimezones()[0];
    slotCount = setTimeSlots(emptyHearings).length;
  });

  test('Matches snapshot with default props', () => {
    // Run the test
    const button = render(
      <TimeSlot roTimezone={roTimezone} hearings={emptyHearings} fetchScheduledHearings={fetchScheduledHearings} />
    );

    // There should be 1 button for each time slot and 1 button to change to custom time
    expect(button.getAllByRole('button')).toHaveLength(slotCount + 1);
    expect(document.getElementsByClassName('time-slot-button-toggle')).toHaveLength(1);
    expect(document.getElementById(`hearing-time-${time}`)).toBeNull();
    expect(document.getElementsByClassName('time-slot-container')).toHaveLength(2);
    expect(button).toMatchSnapshot();
  });

  test('Changes between custom and pre-defined times when button link clicked', () => {
    // Run the test
    const timeSlot = render(
      <TimeSlot
        roTimezone={roTimezone}
        hearings={emptyHearings}
        onChange={onChange}
        fetchScheduledHearings={fetchScheduledHearings}
        hearing={{ scheduledTimeString: time }}
      />
    );

    // Click the toggle
    fireEvent.click(screen.getByText('Choose a custom time'));

    // Check that the correct elements are displayed
    expect(timeSlot.getAllByRole('button')).toHaveLength(1);
    expect(document.getElementsByClassName('time-slot-button-toggle')).toHaveLength(1);
    expect(document.getElementsByClassName('time-slot-container')).toHaveLength(0);

    // Click the toggle
    fireEvent.click(screen.getByText('Choose a time slot'));

    // Check that the correct elements are displayed
    expect(timeSlot.getAllByRole('button')).toHaveLength(slotCount + 1);
    expect(document.getElementsByClassName('time-slot-button-toggle')).toHaveLength(1);
    expect(document.getElementsByClassName('time-slot-container')).toHaveLength(2);

    expect(timeSlot).toMatchSnapshot();
  });

  test('Selects a time slot when clicked', () => {
    // Run the test
    const timeSlot = render(
      <TimeSlot
        roTimezone={roTimezone}
        hearings={emptyHearings}
        onChange={onChange}
        fetchScheduledHearings={fetchScheduledHearings}
        hearing={{ scheduledTimeString: time }}
      />
    );

    // Click 2 different hearing times
    fireEvent.click(screen.getByText(formatTimeSlotLabel(time, roTimezone)));
    fireEvent.click(screen.getByText(formatTimeSlotLabel(time2, roTimezone)));

    // Check that the correct elements are displayed
    expect(timeSlot.getAllByRole('button')).toHaveLength(slotCount + 1);
    expect(document.getElementsByClassName('time-slot-button-selected')).toHaveLength(1);
    expect(timeSlot).toMatchSnapshot();
  });
})
;
