// External Dependencies
import React, { useState } from 'react';
import PropTypes from 'prop-types';
import moment from 'moment-timezone';

// Local Dependencies
import { setTimeSlots } from '../../utils';
import { TimeSlotButton } from './TimeSlotButton';
import Button from '../../../components/Button';
import SmallLoader from '../../../components/SmallLoader';
import { LOGO_COLORS } from '../../../constants/AppConstants';
import { TimeModal } from '../modalForms/TimeModal';

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

  // Manage the modal for time entry
  const [timeModal, setTimeModal] = useState(false);
  const toggleTimeModal = () => setTimeModal((val) => !val);

  // Filter the available time slots to fill in the hearings
  const beginsAt = hearing?.hearingDay?.beginsAt;
  const numberOfSlots = hearing?.hearingDay?.totalSlots;
  const slotLengthMinutes = hearing?.hearingDay?.slotLengthMinutes;
  const slots = setTimeSlots({ scheduledHearingsList, ro, roTimezone, beginsAt, numberOfSlots, slotLengthMinutes });

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
              onClick={() => toggleTimeModal()}
              classNames={['time-slot-button-toggle']}
            >Choose a custom time</Button>
          </div>
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
          {timeModal && <TimeModal
            onCancel={toggleTimeModal}
            onConfirm={(time) => {
              handleChange(time);
              toggleTimeModal();
            }}
            ro={{
              city: 'Los Angeles, CA',
              timezone: 'America/Los_Angeles'
            }}
          />}
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
