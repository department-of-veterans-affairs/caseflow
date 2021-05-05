// React
import React, { useState } from 'react';
// Libraries
import PropTypes from 'prop-types';
import Select from 'react-select';
import moment from 'moment-timezone';
// Components
import Modal from '../../../components/Modal';

const generateTimes = (roTimezone, intervalMinutes = 15) => {
  // Start at midnight '00:00' is the first minute of a day
  const currentTime = moment.tz('00:00', 'HH:mm', roTimezone);
  // End at 23:59, the last minute of a day
  const elevenFiftyNine = moment.tz('23:59', 'HH:mm', roTimezone);

  const times = [];

  // Go through the day in fifteen minute increments and store each increment
  while (currentTime.isBefore(elevenFiftyNine)) {
    // Moment has mutable objects so clone() is necessary
    times.push(currentTime.clone());
    currentTime.add(intervalMinutes, 'minute');
  }

  return times;
};

const moveTimesToEndOfArray = (newFirstValue, times) => {
  // Find the index of newFirstValue
  const firstValueIndex = times.findIndex((time) => time.isSame(newFirstValue));

  // Remove all values before newFirstValue from the front of the array
  const beforeFirstValue = times.slice(0, firstValueIndex);
  const afterFirstValue = times.slice(firstValueIndex);

  // Add the values back onto the end of the array
  return afterFirstValue.concat(beforeFirstValue);
};

const formatTimesToOptionObjects = (times) => {
  return times.map((time) => {
    return {
      label: time.format('h:mm A'),
      value: time
    };
  });
};

const generateOrderedTimeOptions = (roTimezone) => {

  // Get an array with every fifteen minute increment in a day
  // [00:00, 00:15, ... , 23:45]
  const times = generateTimes(roTimezone);
  // Move everything after beginsAt to the end of the array
  const beginsAt = moment.tz('08:30', 'HH:mm', roTimezone);
  const reorderedTimes = moveTimesToEndOfArray(beginsAt, times);
  // Put the times into the format expected by the select
  const options = formatTimesToOptionObjects(reorderedTimes);

  return options;
};

const matchesHour = (candidate, input, exact = false) => {
  const candidateHourString = candidate.value.format('h');

  return exact ? candidateHourString === input : candidateHourString.startsWith(input);
};

const matchesAny = (candidate, input) => {
  if (input.includes(':')) {
    // Split into hours and minutes
    const [hour, minutesAndAmPm] = input.split(':');

    // Check that the hour matches exactly and the minutes+ampm are present
    return matchesHour(candidate, hour, true) && matchesAny(candidate, minutesAndAmPm);
  }
  if (!input.includes(':')) {
  // Produce a time like '400pm' or '800am' for string searching
    const candidateNoColon = candidate.value.format('hhmmA');
    // Remove spaces, force upper case so AM/PM searching works
    const inputNoColonOrSpaces = input.replace(' ', '').toUpperCase();

    return candidateNoColon.includes(inputNoColonOrSpaces);
  }
};

const getTimezoneAbbreviation = (timezone) => {
  return 'CDT';
};

// Custom search logic entry point
const filterOptions = (candidate, input) => {
  // If only one character in the input assume it represents an hour
  if (input.length === 1) {
    return matchesHour(candidate, input);
  }
  if (input.length === 2 && input.endsWith(':')) {
    return matchesHour(candidate, input[0], true);
  }
  if (input.length >= 2) {
    return matchesAny(candidate, input);
  }
};

// Should maybe be made part of the "Alert" component?
const InfoAlert = ({ timeString }) => {
  return (
    <div style={{ display: 'flex', alignItems: 'center' }}>
      <div style={{ background: 'rgb(224, 222, 220)', width: '1rem', height: '4rem', display: 'inline-block', marginRight: '1.5rem' }} />
      <div style={{ display: 'inline-block' }}><i>{`The hearing will start at ${timeString} Eastern Time`}</i></div>
    </div>
  );
};

InfoAlert.propTypes = {
  timeString: PropTypes.string
};

const TimeSelect = ({ roTimezone, onSelect, error, clearError }) => {

  const customStyles = {
    // Hide the dropdown arrow on the right side
    indicatorSeparator: () => ({ display: 'none' }),
    dropdownIndicator: () => ({ display: 'none' }),
    // Set the height of the select component
    valueContainer: (styles) => ({
      ...styles,
      border: error ? '2px solid red' : styles.border,
      height: '44px',
      minHeight: '44px',
    }),
    // Fix selected text positioning problem caused by adjusting height
    singleValue: () => ({
      padding: '0',
      margin: '0'
    })
  };
  // Managing this so we can force it to stay closed until typed into
  const [menuOpen, setMenuOpen] = useState(false);
  const hideMenu = () => setMenuOpen(false);
  const showMenu = () => setMenuOpen(true);
  const handleInputChange = (query, { action }) => {
    // Clear the error as soon as the input is interacted with
    clearError();
    // Show the menu if there are any characters in the select box
    if (action === 'input-change' && query) {
      showMenu();
    }
    // When deleting, if no characters in select box, hide the menu
    if (action === 'input-change' && !query) {
      hideMenu();
    }
  };

  const options = generateOrderedTimeOptions(roTimezone);

  return (
    <div style={{ borderRadius: '5px', background: 'rgb(224, 222, 220)', width: '50%', marginTop: '16px', marginBottom: '32px', display: 'flex', alignItems: 'center' }}>
      <div style={{ width: '75%', display: 'inline-block' }}>
        <Select
          // Make this a controlled select
          onChange={onSelect}
          // Backspace will clear a selected option, also show an 'x' to clear
          isClearable
          // Make this a searchable react-select
          isSearchable
          // The array of options
          options={options}
          // Custom searching logic
          filterOption={filterOptions}
          // Several options together to force the menu to be closed until typed into
          onInputChange={handleInputChange}
          menuIsOpen={menuOpen}
          onBlur={hideMenu}
          closeMenuOnSelect
          blurInputOnSelect
          // Dont show the placeholder text
          placeholder=""
          // Don't let menu get long enough to scroll the modal
          maxMenuHeight="300"
          // Hide some elements of react-select, deal with error state, adjust height of component
          styles={customStyles}
        />
      </div>
      <div style={{ width: '25%', display: 'inline-block', color: 'black', textAlign: 'center' }}><strong>{getTimezoneAbbreviation(roTimezone)}</strong></div>
    </div>
  );
};

TimeSelect.propTypes = {
  roTimezone: PropTypes.string,
  onSelect: PropTypes.func,
  error: PropTypes.bool,
  clearError: PropTypes.func
};

export const CustomTimeModal = ({ onConfirm, onCancel, roCity, roTimezone }) => {
  // Error message state
  const [error, setError] = useState();
  // Control the TimeSelect component
  const [selectedOption, setSelectedOption] = useState();
  // Check if we have a value, if yes setError, if not, submit.
  const handleConfirm = () =>
    selectedOption ? onConfirm(selectedOption?.value) : setError('Please enter a hearing start time.');

  return (
    <Modal
      title="Create a custom time slot"
      buttons={[
        {
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Cancel',
          onClick: onCancel
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: 'Create time slot',
          onClick: handleConfirm
        },
      ]}
      closeHandler={onCancel}
      id="custom-time-modal"
    >
      <div><strong>Choose a hearing start time for <span style={{ whiteSpace: 'nowrap' }}>{roCity}</span></strong></div>
      <div>Enter time as hh:mm AM/PM, for example "1:00 PM"</div>

      {error && <div style={{ color: 'red', paddingTop: '16px' }}>{error}</div>}

      <TimeSelect
        roTimezone={roTimezone}
        onSelect={setSelectedOption}
        error={error}
        clearError={() => setError('')}
      />
      <div style={{ height: '100px' }}>
        {roTimezone !== 'America/New_York' && selectedOption &&
          <InfoAlert timeString={selectedOption?.value.tz('America/New_York').format('h:mm A')} />
        }
      </div>
    </Modal>
  );
};

CustomTimeModal.propTypes = {
  roCity: PropTypes.string,
  roTimezone: PropTypes.string,
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func,
};

