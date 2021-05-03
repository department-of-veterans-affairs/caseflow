import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import Select from 'react-select';

const generateOrderedTimeOptions = (roTimezone) => {
  const options = [
    { value: 'chocolate', label: 'Chocolate' },
    { value: 'strawberry', label: 'Strawberry' },
    { value: 'vanilla', label: 'Vanilla' }
  ];

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
