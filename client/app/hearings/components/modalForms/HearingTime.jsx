import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import moment from 'moment-timezone';

import HEARING_TIME_OPTIONS from '../../../../constants/HEARING_TIME_OPTIONS';
import HEARING_TIME_RADIO_OPTIONS from '../../../../constants/HEARING_TIME_RADIO_OPTIONS';
import RadioField from '../../../components/RadioField';
import SearchableDropdown from '../../../components/SearchableDropdown';

export const getAssignHearingTime = (time, day) => {
  return {
    // eslint-disable-next-line id-length
    h: time.split(':')[0],
    // eslint-disable-next-line id-length
    m: time.split(':')[1],
    offset: moment.tz(day.hearingDate || day.scheduledFor, day.timezone || 'America/New_York').format('Z')
  };
};

const formStyling = css({
  '& .cf-form-radio-option:not(:last-child)': {
    display: 'inline-block',
    marginRight: '25px'
  },
  marginBottom: 0
});

let index = 0;

export default class HearingTime extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      isOther: this.getIsOther(),
      index: (index += 1)
    };
  }

  componentDidUpdate(prevProps) {
    if (!_.isEqual(this.props.value, prevProps.value)) {
      this.setState({
        isOther: this.getIsOther()
      });
    }
  }

  getIsOther = () => {
    const selectedOption = _.find(this.getTimeOptions(), (opt) => opt.value === this.props.value);

    return _.isUndefined(selectedOption);
  };

  getTimeOptions = (readOnly) => {
    const { regionalOffice } = this.props;

    return _.map(
      regionalOffice === 'C' ? HEARING_TIME_RADIO_OPTIONS.central : HEARING_TIME_RADIO_OPTIONS.default,
      (obj) => _.extend(obj, { disabled: readOnly })
    );
  };

  onRadioChange = (value) => {
    if (value === 'other') {
      this.setState({ isOther: true });
      this.props.onChange(null);
    } else {
      this.setState({ isOther: false });
      this.props.onChange(value);
    }
  };

  render() {
    const { errorMessage, value, readOnly } = this.props;

    return (
      <React.Fragment>
        <span {...formStyling}>
          <RadioField
            errorMessage={errorMessage}
            name={`hearingTime${this.state.index}`}
            label="Time"
            strongLabel
            options={this.getTimeOptions(readOnly)}
            onChange={this.onRadioChange}
            value={this.state.isOther ? 'other' : value}
          />
        </span>
        {this.state.isOther && (
          <SearchableDropdown
            readOnly={readOnly}
            name={`optionalHearingTime${this.state.index}`}
            placeholder="Select a time"
            options={HEARING_TIME_OPTIONS}
            value={value}
            onChange={(option) => this.props.onChange(option ? option.value : null)}
            hideLabel
          />
        )}
      </React.Fragment>
    );
  }
}

HearingTime.propTypes = {
  errorMessage: PropTypes.string,
  onChange: PropTypes.func,
  readOnly: PropTypes.bool,
  regionalOffice: PropTypes.string,
  value: PropTypes.string
};
