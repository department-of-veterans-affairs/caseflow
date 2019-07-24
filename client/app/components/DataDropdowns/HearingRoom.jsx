import { HEARING_ROOM_OPTIONS } from './constants';

import React from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../SearchableDropdown';
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
    const { name, label, onChange, readOnly, errorMessage, placeholder } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={label}
        strongLabel
        readOnly={readOnly}
        value={this.getSelectedOption()}
        onChange={(option) => onChange((option || {}).value, (option || {}).label)}
        options={HEARING_ROOM_OPTIONS}
        errorMessage={errorMessage}
        placeholder={placeholder} />
    );
  }
}

HearingRoomDropdown.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  readOnly: PropTypes.bool,
  placeholder: PropTypes.string,
  errorMessage: PropTypes.string
};

HearingRoomDropdown.defaultProps = {
  name: 'room',
  label: 'Hearing Room'
};
