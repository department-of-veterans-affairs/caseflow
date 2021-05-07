// React
import React, { useState } from 'react';
// Libraries
import PropTypes from 'prop-types';
import Select from 'react-select';
import moment from 'moment-timezone';
// Components
import Modal from '../../../components/Modal';
// Styling
import { css } from 'glamor';
import { COLORS } from 'app/constants/AppConstants';

/*
* TIME LIST GENERATION START
*/
// Get an array with every fifteen minute increment in a day
// [00:00, 00:15, ... , 23:45]
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
// Move the part of the arrawy after newFirstValue to the end of the array
const moveTimesToEndOfArray = (newFirstValue, times) => {
  // Find the index of newFirstValue
  const firstValueIndex = times.findIndex((time) => time.isSame(newFirstValue));

  // Remove all values before newFirstValue from the front of the array
  const beforeFirstValue = times.slice(0, firstValueIndex);
  const afterFirstValue = times.slice(firstValueIndex);

  // Add the values back onto the end of the array
  return afterFirstValue.concat(beforeFirstValue);
};
// Convert each time in the array into the expected 'option' format for react-select
const formatTimesToOptionObjects = (times) => {
  return times.map((time) => {
    return {
      label: time.format('h:mm A'),
      value: time
    };
  });
};
// Generate a time for every 15m increment in a day.
// Then move every time before beginsAt to the end of
// the array to beginsAt appears first.
const generateOrderedTimeOptions = (roTimezone, beginsAt = moment.tz('08:30', 'HH:mm', roTimezone)) => {
  const times = generateTimes(roTimezone);
  const reorderedTimes = moveTimesToEndOfArray(beginsAt, times);
  const options = formatTimesToOptionObjects(reorderedTimes);

  return options;
};

/*
* TIME LIST GENERATION END
*/

/*
* CUSTOM LIST FILTERING START
*/
// Checks if the input matches the hour of a candidate.value which is a moment object
const matchesHour = (candidate, input, exact = false) => {
  const candidateHourString = candidate.value.format('h');

  return exact ? candidateHourString === input : candidateHourString.startsWith(input);
};
const removeOneLeadingZero = (string) => {
  return string[0] === '0' ? string.slice(1) : string;
};
// Checks if the input matches any part of a candidate.value which is a moment object
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
    const noColonOrSpaces = input.replace(' ', '').toUpperCase();
    // Remove a leading zero if there is one
    const noLeadingZero = removeOneLeadingZero(noColonOrSpaces);

    return candidateNoColon.includes(noLeadingZero);
  }
};
// Filter the options list to display only options that match
// what's been typed into the input
const filterOptions = (candidate, input) => {
  // If only one character in the input assume it represents an hour
  if (input.length === 1) {
    return matchesHour(candidate, input);
  }
  // If one character and ':' in the input assume it represents an hour
  if (input.length === 2 && input.endsWith(':')) {
    return matchesHour(candidate, input[0], true);
  }
  // For everything else, send to matchesAny, which also handles ':'
  if (input.length >= 2) {
    return matchesAny(candidate, input);
  }
};

/*
* CUSTOM LIST FILTERING END
*/
// Given a long timezone like "America/Los_Angeles" return the
// short version like "PDT" or "PST" (depending on date)
const getTimezoneAbbreviation = (timezone) => {
  // Create a moment object so we can extract the timezone
  // abbreviation like 'PDT'
  return moment.tz('00:00', 'HH:mm', timezone).format('z');
};

// Should maybe be made part of the "Alert" component? Seemed very different
const InfoAlert = ({ timeString }) => {
  const alertContainerStyles = css({
    display: 'flex',
    alignItems: 'center'
  });

  const greyRectangleStyles = css({
    background: COLORS.GREY_LIGHT,
    width: '1rem',
    height: '4rem',
    display: 'inline-block',
    marginRight: '1.5rem'
  });
  const textDivStyles = css({
    display: 'inline-block',
    fontStyle: 'italic'
  });

  return (
    <div className="info-alert" {...alertContainerStyles}>
      <div {...greyRectangleStyles} />
      <div {...textDivStyles}>{`The hearing will start at ${timeString} Eastern Time`}</div>
    </div>
  );
};

InfoAlert.propTypes = {
  timeString: PropTypes.string
};

const TimeSelect = ({ roTimezone, onSelect, error, clearError }) => {

  const customSelectStyles = {
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
    }),
    // Change the highlight colors in the dropdown to gray
    option: (styles, { isFocused }) => ({
      ...styles,
      color: isFocused ? 'white' : styles.color,
      backgroundColor: isFocused ? COLORS.GREY : null,
      ':hover': {
        ...styles[':hover'],
        backgroundColor: COLORS.GREY,
        color: 'white'
      },
    })
  };
  const containerStyles = css({
    borderRadius: '5px',
    background: COLORS.GREY_LIGHT,
    width: '50%',
    marginTop: '16px',
    marginBottom: '32px',
    display: 'flex',
    alignItems: 'center'
  });
  const selectContainerStyles = css({
    width: '75%',
    display: 'inline-block'
  });
  const timezoneAbbreviationContainer = css({
    width: '25%',
    display: 'inline-block',
    textAlign: 'center',
    color: 'black',
    fontWeight: 'bold'
  });

  // This code exists to customize when the menu is shown/hidden
  // our requirements have the menu ONLY shown when there's something
  // entered in the input and nothing has been selected.
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
    <div className="time-select" {...containerStyles}>
      <div {...selectContainerStyles}>
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
          // Hide some elements of react-select, deal with error state, adjust height of component
          styles={customSelectStyles}
        />
      </div>
      <div {...timezoneAbbreviationContainer}>
        {getTimezoneAbbreviation(roTimezone)}
      </div>
    </div>
  );
};

TimeSelect.propTypes = {
  roTimezone: PropTypes.string,
  onSelect: PropTypes.func,
  error: PropTypes.bool,
  clearError: PropTypes.func
};

export const TimeModal = ({ onCancel, onConfirm, ro }) => {
  // Error message state
  const [error, setError] = useState();
  // Control the TimeSelect component
  const [selectedOption, setSelectedOption] = useState();
  // Check if we have a value, if yes setError, if not, format and submit.
  const handleConfirm = () => {
    if (!selectedOption) {
      setError('Please enter a hearing start time.');
    }
    if (selectedOption) {
      // Take the moment value and convert it into the format TimeSlot expects
      // - Eastern timezone
      // - 13:15 (24hr clock)
      const formattedValue = selectedOption.value.tz('America/New_York').format('HH:mm');

      window.analyticsEvent('Hearings', 'Schedule Veteran – Choose a custom time', formattedValue);
      onConfirm(formattedValue);
    }
  };

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
      customStyles={css({ overflow: 'hidden' })}
    >
      <div {...css({ height: '200px' })}>
        <div {...css({ fontWeight: 'bold' })}>
          Choose a hearing start time for <span {...css({ whiteSpace: 'nowrap' })}>{ro.city}</span>
        </div>
        <div>Enter time as hh:mm AM/PM, for example "1:00 PM"</div>

        {error && <div {...css({ color: 'red', paddingTop: '16px' })}>{error}</div>}

        <TimeSelect
          roTimezone={ro.timezone}
          onSelect={setSelectedOption}
          error={error}
          clearError={() => setError('')}
        />

        {ro.timezone !== 'America/New_York' && selectedOption &&
          <InfoAlert timeString={selectedOption?.value.tz('America/New_York').format('h:mm A')} />
        }

      </div>
    </Modal>
  );
};

TimeModal.propTypes = {
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func,
  ro: PropTypes.shape({
    city: PropTypes.string,
    timezone: PropTypes.string,
  }),
};

