import React from 'react';

import { TimeSlot } from 'app/hearings/components/scheduleHearing/TimeSlot';
import { render, fireEvent, screen } from '@testing-library/react';
import { roTimezones, setTimeSlots, formatTimeSlotLabel } from 'app/hearings/utils';
import { axe } from 'jest-axe';

const emptyHearings = [];
const defaultProps = {
  roTimezone: roTimezones()[0],
  hearings: emptyHearings,
  fetchScheduledHearings: jest.fn(),
  onChange: jest.fn()
};

const setup = (props = {}) => {
  const utils = render(<TimeSlot {...defaultProps} {...props} />);
  const container = utils.container;
  const timeSlots = setTimeSlots(props.hearings || defaultProps.hearings);

  return { container, utils, timeSlots };
};

describe('TimeSlot', () => {
  it('renders correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have 1 button for each time slot and 1 button to change to custom time', () => {
    const { utils, timeSlots } = setup();

    expect(utils.getAllByRole('button')).toHaveLength(timeSlots.length + 1);
    expect(document.getElementsByClassName('time-slot-button-toggle')).toHaveLength(1);
    expect(document.getElementsByClassName('time-slot-container')).toHaveLength(2);
  });

  test('Changes between custom and pre-defined times when button link clicked', () => {
    const { utils, timeSlots } = setup();

    // Click the toggle
    fireEvent.click(screen.getByText('Choose a custom time'));

    // Check that the correct elements are displayed
    expect(utils.getAllByRole('button')).toHaveLength(1);
    expect(document.getElementsByClassName('time-slot-button-toggle')).toHaveLength(1);
    expect(document.getElementsByClassName('time-slot-container')).toHaveLength(0);

    // Click the toggle
    fireEvent.click(screen.getByText('Choose a time slot'));

    // Check that the correct elements are displayed
    expect(utils.getAllByRole('button')).toHaveLength(timeSlots.length + 1);
    expect(document.getElementsByClassName('time-slot-button-toggle')).toHaveLength(1);
    expect(document.getElementsByClassName('time-slot-container')).toHaveLength(2);
  });

  test('Selects a time slot when clicked', () => {
    const { utils, timeSlots } = setup();

    // Click 2 different hearing times
    fireEvent.click(screen.getByText(formatTimeSlotLabel('08:30', defaultProps.roTimezone)));
    fireEvent.click(screen.getByText(formatTimeSlotLabel('09:30', defaultProps.roTimezone)));

    // Check that the correct elements are displayed
    expect(utils.getAllByRole('button')).toHaveLength(timeSlots.length + 1);
    expect(document.getElementsByClassName('time-slot-button-selected')).toHaveLength(1);
  });
})
;
