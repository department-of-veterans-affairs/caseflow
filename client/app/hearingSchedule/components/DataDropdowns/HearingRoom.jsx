import { HEARING_ROOM_OPTIONS } from './constants';

import React from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../../components/SearchableDropdown';
import _ from 'lodash';

export default class HearingRoomDropdown extends React.Component {

  getSelectedOption = () => {
    const { value } = this.props;

    return _.find(HEARING_ROOM_OPTIONS, (opt) => opt.value === value) ||
      {
        value: null,
        label: null
      };
  }

  render() {
    const { name, label, onChange, readOnly } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={label}
        strongLabel
        readOnly={readOnly}
        value={this.getSelectedOption()}
        onChange={(option) => onChange(option.value)}
        options={HEARING_ROOM_OPTIONS} />
    );
  }
}

HearingRoomDropdown.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.number,
  onChange: PropTypes.func.isRequired,
  readOnly: PropTypes.bool
};

HearingRoomDropdown.defaultProps = {
  name: 'room',
  label: 'Hearing Room'
};
