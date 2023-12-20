// similar to ListItemPicker only this saves
// the state of the current selected item and shows it as a checkbox

import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import Checkbox from './Checkbox';

const listStyling = css({
  paddingBottom: 0,
  margin: 0,
  maxHeight: '345px',
  wordBreak: 'break-word',
  width: '250px',
  overflowY: 'none',
  listStyleType: 'none',
  fontSize: '1.6rem',
  paddingLeft: 0
});
const listItemStyling = css({
  padding: '1px'
});

class ListItemPickerCheckbox extends React.PureComponent {
  onClick = (isChecked, event) => {
    const value = event.target.name;

    this.props.setSelectedValue(value);
  };

  render = () => {
    return <ul {...this.props.dropdownFilterViewListStyle} {...listStyling}>
      {this.props.options.map((option, index) => {
        return <li key={index} {...listItemStyling}>
          <Checkbox
            unpadded
            label={option.value}
            name={option.value}
            onChange={this.onClick}
            value={this.props.selected(option.value)}
          />
        </li>;
      })}
    </ul>;
  }
}

ListItemPickerCheckbox.propTypes = {
  options: PropTypes.array.isRequired,
  setSelectedValue: PropTypes.func.isRequired,
  selected: PropTypes.func.isRequired
};

export default ListItemPickerCheckbox;

