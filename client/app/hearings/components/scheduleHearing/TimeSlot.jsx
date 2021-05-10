// External Dependencies
import React, { useState } from 'react';
import PropTypes from 'prop-types';
import moment from 'moment-timezone';

// Local Dependencies
import { setTimeSlots, regionalOfficeDetails } from '../../utils';
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

  // Extract the necessary values for timeslot calculation from state
  const beginsAt = hearing?.hearingDay?.beginsAt;
  const numberOfSlots = hearing?.hearingDay?.totalSlots;
  const slotLengthMinutes = hearing?.hearingDay?.slotLengthMinutes;
  const hearingDayDate = hearing?.hearingDay?.scheduledFor;
  // Get the timeslots
  const slots = setTimeSlots({
    scheduledHearingsList,
    ro,
    roTimezone,
    beginsAt,
    numberOfSlots,
    slotLengthMinutes,
    selected,
    hearingDayDate
  });

  // Setup the click handler for each time slot
  const handleChange = (time) => {
    setSelected(time.tz('America/New_York').format('HH:mm'));
    // onChange('scheduledTimeString', time.tz(roTimezone).format('HH:mm'));
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
                  onClick={() => handleChange(slot.time)}
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
                  onClick={() => handleChange(slot.time)}
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
              city: regionalOfficeDetails(ro) ? regionalOfficeDetails(ro).city : '',
              timezone: roTimezone
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
