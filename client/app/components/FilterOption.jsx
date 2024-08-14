import React from 'react';
import PropTypes from 'prop-types';

const listStyling = {
  paddingBottom: 0,
  margin: 0,
  maxHeight: '345px',
  wordBreak: 'break-word',
  width: '218px',
  overflowY: 'auto',
  listStyleType: 'none',
  paddingLeft: 0
};
const listItemStyling = {
  padding: '1px',
  position: 'relative'
};

const FilterOption = ({ options, setSelectedValue,
  dropdownFilterViewListStyle, dropdownFilterViewListItemStyle }) => {

  const handleChange = (event) => {
    setSelectedValue(event.target.value);
  };

  const dropdownFilterListStyle = { ...dropdownFilterViewListStyle, ...listStyling };
  const dropdownFilterListItemStyle = { ...dropdownFilterViewListItemStyle, ...listItemStyling };

  return <ul style={dropdownFilterListStyle}>
    {options.map((option, index) => {
      return <li className="cf-filter-option-row" key={index} style={dropdownFilterListItemStyle}>
        <input
          type="checkbox"
          id={`${index}-${option.value}`}
          value={option.value}
          checked={option.checked}
          onChange={handleChange} />
        <label htmlFor={`${index}-${option.value}`}>
          {option.displayText}
        </label>

      </li>;
    })}
  </ul>;
};

FilterOption.propTypes = {
  options: PropTypes.array.isRequired,
  setSelectedValue: PropTypes.func.isRequired,
  dropdownFilterViewListStyle: PropTypes.object,
  dropdownFilterViewListItemStyle: PropTypes.object
};

export default FilterOption;
