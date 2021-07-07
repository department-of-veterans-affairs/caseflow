// React
import React, { useState } from 'react';
// Libraries
import PropTypes from 'prop-types';
import Select from 'react-select';
// Styling
import { css } from 'glamor';
import { COLORS } from 'app/constants/AppConstants';
// Caseflow
import { generateOrderedTimeOptions, filterOptions, getTimezoneAbbreviation } from '../../utils';

export const TimeSelect = ({ roTimezone, onSelect, error, clearError, hearingDayDate }) => {

  const customSelectStyles = {
    // Hide the dropdown arrow on the right side
    indicatorSeparator: () => ({ display: 'none' }),
    dropdownIndicator: () => ({ display: 'none' }),
    // Set the height of the select component
    valueContainer: (styles) => ({
      ...styles,
      // Cascading lineHeight is 200%, which makes the selected text vertically uncentered
      lineHeight: 'normal',
      border: error ? '2px solid red' : styles.border,
      height: '44px',
      minHeight: '44px',
    }),
    // Fix selected text positioning problem caused by adjusting height
    // Without this, the text positioning is strange if input is something
    // long like "12:30pm" (or for testing 12::::30:::::PM)
    singleValue: (styles) => {
      return {
        ...styles,
        transform: 'translateY(-2px)'
      };
    },
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

  const options = generateOrderedTimeOptions(roTimezone, hearingDayDate);

  return (
    <div className="time-select" {...containerStyles}>
      <div {...selectContainerStyles}>
        <Select
          // Accessibility
          aria-label="time select"
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
          // Set the maximum height
          maxMenuHeight={175}
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
  error: PropTypes.string,
  clearError: PropTypes.func,
  hearingDayDate: PropTypes.string
};
