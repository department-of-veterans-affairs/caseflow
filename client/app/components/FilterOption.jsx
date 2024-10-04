import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

const listStyling = css({
  paddingBottom: 0,
  margin: 0,
  maxHeight: '345px',
  wordBreak: 'break-word',
  width: '218px',
  overflowY: 'auto',
  listStyleType: 'none',
  paddingLeft: 0
});
const listItemStyling = css({
  padding: '1px',
  position: 'relative'
});

const FilterOption = ({ options, setSelectedValue,
  dropdownFilterViewListStyle, dropdownFilterViewListItemStyle }) => {

  const handleChange = (event) => {
    setSelectedValue(event.target.value);
  };

  return <ul {...dropdownFilterViewListStyle} {...listStyling}>
    {options.map((option, index) => {
      return <li className="cf-filter-option-row" key={index} {...dropdownFilterViewListItemStyle} {...listItemStyling}>
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
