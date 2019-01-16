import { HEARING_ROOM_OPTIONS } from './constants';

import React from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../../components/SearchableDropdown';
import _ from 'lodash';

export default class HearingRoomDropdown extends React.Component {

  componentDidUpdate() {
    const { value, onChange } = this.props;

    if (typeof (value) === 'string') {
      onChange(this.getValue());
    }
  }

  getValue = () => {
    const { value, options } = this.props;

    if (!value) {
      return null;
    }

    if (typeof (value) === 'string') {
      return _.find(options, (opt) => opt.value === value);
    }

    return value;
  }

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
