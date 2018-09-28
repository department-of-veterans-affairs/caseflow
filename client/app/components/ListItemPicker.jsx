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
  padding: '1px'
});

const ListItemPicker = ({ options, setSelectedValue,
  dropdownFilterViewListStyle, dropdownFilterViewListItemStyle }) => {

  const onClick = (event) => {
    setSelectedValue(event.target.value);
  };

  return <ul {...dropdownFilterViewListStyle} {...listStyling}>
    {options.map((option, index) => {
      return <li key={index} {...dropdownFilterViewListItemStyle} {...listItemStyling} onClick={onClick}>
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
  setSelectedValue: PropTypes.func.isRequired
};

export default ListItemPicker;
