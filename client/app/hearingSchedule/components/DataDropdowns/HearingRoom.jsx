import { HEARING_ROOM_OPTIONS } from './constants';

import React from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../../components/SearchableDropdown';

export default class HearingRoomDropdown extends React.Component {
  render() {
    const { name, label, onChange, value } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={label}
        strongLabel
        value={value}
        onChange={onChange}
        options={HEARING_ROOM_OPTIONS} />
    );
  }
}

HearingRoomDropdown.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.object,
  onChange: PropTypes.func.isRequired
};

HearingRoomDropdown.defaultProps = {
  name: 'room',
  label: 'Hearing Room'
};
