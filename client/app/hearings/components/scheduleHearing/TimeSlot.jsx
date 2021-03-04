// External Dependencies
import React, { useState } from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { setTimeSlots } from '../../utils';
import { TimeSlotButton } from './TimeSlotButton';
import Button from '../../../components/Button';
import SmallLoader from '../../../components/SmallLoader';
import { HearingTime } from '../modalForms/HearingTime';
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
  const slots = setTimeSlots(scheduledHearingsList, ro);

  // Setup the click handler for each time slot
  const handleClick = (time) => {
    // Set the selected time slot
    setSelected(time);

    // Use the onChange callback to set the hearing time
    onChange('scheduledTimeString', time);
  };

  // Create a hearing Time ID to associate the label with the appropriate form element
  const hearingTimeId = `hearing-time-${hearing?.scheduledTimeString}`;

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
            <HearingTime
              hideLabel
              enableZone
              disableRadioOptions
              id={hearingTimeId}
              localZone={roTimezone}
              onChange={(scheduledTimeString) => onChange('scheduledTimeString', scheduledTimeString)}
              value={hearing?.scheduledTimeString}
            />
          ) : (
            <div className="time-slot-button-container">
              <div className="time-slot-container" >
                {slots.slice(0, slots.length / 2).map((slot) => (
                  <TimeSlotButton
                    {...slot}
                    key={slot.key}
                    roTimezone={roTimezone}
                    selected={selected === slot.hearingTime}
                    onClick={() => handleClick(slot.hearingTime)}
                  />
                ))}
              </div>
              <div className="time-slot-container">
                {slots.slice(slots.length / 2, slots.length).map((slot) => (
                  <TimeSlotButton
                    {...slot}
                    key={slot.key}
                    roTimezone={roTimezone}
                    selected={selected === slot.hearingTime}
                    onClick={() => handleClick(slot.hearingTime)}
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
