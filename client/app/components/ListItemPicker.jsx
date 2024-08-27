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
  padding: '1px'
};

const ListItemPicker = ({ options, setSelectedValue,
  dropdownFilterViewListStyle, dropdownFilterViewListItemStyle }) => {

  const onClick = (event) => {
    setSelectedValue(event.target.value);
  };

  const listStyle = { ...dropdownFilterViewListStyle, ...listStyling };
  const itemStyle = { ...dropdownFilterViewListItemStyle, ...listItemStyling };

  return <ul style={listStyle}>
    {options.map((option, index) => {
      return <li key={index} style={itemStyle} onClick={onClick}>
        <option
          value={option.value}
          id={`${index}-${option.value}`}
          key={index}>{option.displayText}
        </option>
      </li>;
    })}
  </ul>;
};

ListItemPicker.propTypes = {
  options: PropTypes.array.isRequired,
  setSelectedValue: PropTypes.func.isRequired,
  dropdownFilterViewListStyle: PropTypes.object,
  dropdownFilterViewListItemStyle: PropTypes.object
};

export default ListItemPicker;
