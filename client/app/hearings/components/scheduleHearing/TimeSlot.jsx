// External Dependencies
import React, { useState } from 'react';
import PropTypes from 'prop-types';
import moment from 'moment-timezone';

// Local Dependencies
import {
  setTimeSlots,
  getHourOffsetFromEST,
  TIMEZONES_WITH_LUNCHBREAK
} from '../../utils';
import { TimeSlotButton } from './TimeSlotButton';
import Button from '../../../components/Button';
import SmallLoader from '../../../components/SmallLoader';
import { TimePicker } from '../TimePicker';
import { LOGO_COLORS } from '../../../constants/AppConstants';

export const TimeSlot = ({
  scheduledHearingsList,
  roTimezone,
  onChange,
  hearing,
  fetchingHearings,
  ro
}) => {
  // Create local state to hold the selected time before saving
  const [selected, setSelected] = useState('');

  // Create a local state to switch between the dropdown for custom times
  const [custom, setCustom] = useState(false);

  // Filter the available time slots to fill in the hearings
  const beginsAt = hearing?.hearingDay?.beginsAt;
  const numberOfSlots = hearing?.hearingDay?.totalSlots;
  const slotLengthMinutes = hearing?.hearingDay?.slotLengthMinutes;

  // Get a lunch break time that will be 12:30 when converted to EST
  // America/New_York => '12:30' but America/Chicago => '13:30'
  const lunchBreak = TIMEZONES_WITH_LUNCHBREAK.includes(roTimezone) ?
    {
      time: moment.tz('2020-01-01 12:30', 'America/New_York').
        add(getHourOffsetFromEST(roTimezone), 'hour').
        format('HH:mm'),
      lengthInMinutes: 30
    } :
    {};

  const slots = setTimeSlots({
    scheduledHearingsList,
    ro,
    roTimezone,
    beginsAt,
    numberOfSlots,
    slotLengthMinutes,
    lunchBreak
  });

  // Setup the click handler for each time slot
  const handleChange = (time) => {
    // Set the selected time slot
    setSelected(time);

    // Convert to ro timezone, then set the hearing time in reducer
    const timeInRoZone = moment.tz(time, 'HH:mm', 'America/New_York').tz(roTimezone).
      format('HH:mm');

    onChange('scheduledTimeString', timeInRoZone);
  };

  // Create a hearing Time ID to associate the label with the appropriate form element
  const hearingTimeId = `hearing-time-${hearing?.scheduledTimeString}`;

  // Determine the column length to evenly distribute the time slots
  const columnLength = Math.ceil(slots.length / 2);

  return (
    <React.Fragment>
      <label className="time-slot-label" htmlFor={hearingTimeId}>
         Hearing Time
      </label>
      {fetchingHearings ? (
        <SmallLoader spinnerColor={LOGO_COLORS.QUEUE.ACCENT} message="Loading Hearing Times" />
      ) : (
        <React.Fragment>
          <div>
            <Button
              linkStyling
              onClick={() => setCustom(!custom)}
              classNames={['time-slot-button-toggle']}
            >
                 Choose a {custom ? 'time slot' : 'custom time'}
            </Button>
          </div>
          {custom ? (
            <TimePicker
              id={hearingTimeId}
              roTimezone={roTimezone}
              onChange={handleChange}
              value={hearing?.scheduledTimeString}
            />
          ) : (
            <div className="time-slot-button-container">
              <div className="time-slot-container" >
                {slots.slice(0, columnLength).map((slot) => (
                  <TimeSlotButton
                    {...slot}
                    key={slot.key}
                    roTimezone={roTimezone}
                    selected={selected === slot.hearingTime}
                    onClick={() => handleChange(slot.hearingTime)}
                  />
                ))}
              </div>
              <div className="time-slot-container">
                {slots.slice(columnLength, slots.length).map((slot) => (
                  <TimeSlotButton
                    {...slot}
                    key={slot.key}
                    roTimezone={roTimezone}
                    selected={selected === slot.hearingTime}
                    onClick={() => handleChange(slot.hearingTime)}
                  />
                ))}
              </div>
            </div>
          )}
        </React.Fragment>
      )}
    </React.Fragment>
  );
};

TimeSlot.propTypes = {
  fetchingHearings: PropTypes.bool,
  hearing: PropTypes.object,
  onChange: PropTypes.func,
  scheduledHearingsList: PropTypes.array,
  roTimezone: PropTypes.string,
  ro: PropTypes.string,
};
