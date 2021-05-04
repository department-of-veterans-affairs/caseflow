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
      value: time.format('HH:mm'),
      label: time.format('h:mm A')
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

export const CustomTimeModal = ({ onConfirm, onCancel, roTimezone }) => {
  const options = generateOrderedTimeOptions(roTimezone);
  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Create time slot',
      onClick: onConfirm
    },
  ];

  // Managing this so we can force it to stay closed until typed into
  const [menuOpen, setMenuOpen] = useState(false);
  const handleInputChange = (query, { action }) => {
    if (action === 'input-change' && query) {
      setMenuOpen(true);
    }
    // When deleting, if we end up with a blank string the menu is open
    // by default. This overrides that behavior and closes the menu
    if (action === 'input-change' && !query) {
      setMenuOpen(false);
    }
  };
  const hideMenu = () => {
    setMenuOpen(false);
  };

  // Hide the dropdown arrow on the right side
  const hideStyleFunction = () => ({
    display: 'none'
  });
  const customStyles = {
    // Hiding this removes the "x" to clear, we want to keep that for now
    // indicatorsContainer: hideStyleFunction,
    indicatorSeparator: hideStyleFunction,
    dropdownIndicator: hideStyleFunction
  };

  return (
    <Modal title="Create a custom time slot" buttons={buttons} closeHandler={onCancel} id="custom-time-modal">
      <div>[placeholder text, line1]</div>
      <div>[placeholder text, line2]</div>
      <div>[placeholder text, line3]</div>
      <Select
        // Settings for searching
        isClearable
        isSearchable
        options={options}
        // Don't open until we type
        onInputChange={handleInputChange}
        menuIsOpen={menuOpen}
        onChange={hideMenu}
        onBlur={hideMenu}
        // Hide the dropdown arrow
        styles={customStyles}
      />
    </Modal>
  );
};

CustomTimeModal.propTypes = {
  roTimezone: PropTypes.string,
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func,
};
