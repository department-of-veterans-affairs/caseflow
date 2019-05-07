import React from 'react';
import moment from 'moment';
import { css } from 'glamor';
import RadioField from '../../../components/RadioField';
import SearchableDropdown from '../../../components/SearchableDropdown';
import { TIME_OPTIONS } from '../../../hearings/constants/constants';
import _ from 'lodash';

export const getDisplayTime = (scheduledForTime, timezone) => {
  const option = _.find(TIME_OPTIONS, ['value', scheduledForTime]);
  const val = _.isUndefined(option) ? '' : option.value;

  if (timezone) {
    const tz = moment().tz(timezone).
      format('z');

    return `${val} ${tz}`;
  }

  return val;
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
      index: index += 1
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
  }

  getTimeOptions = (readOnly) => {
    const { regionalOffice } = this.props;

    if (regionalOffice === 'C') {
      return [
        { displayText: '9:00 am',
          value: '09:00',
          disabled: readOnly },
        { displayText: '1:00 pm',
          value: '13:00',
          disabled: readOnly },
        { displayText: 'Other',
          value: 'other',
          disabled: readOnly }
      ];
    }

    return [
      { displayText: '8:30 am',
        value: '08:30',
        disabled: readOnly },
      { displayText: '12:30 pm',
        value: '12:30',
        disabled: readOnly },
      { displayText: 'Other',
        value: 'other',
        disabled: readOnly }
    ];
  }

  onRadioChange = (value) => {
    if (value === 'other') {
      this.setState({ isOther: true });
      this.props.onChange(null);
    } else {
      this.setState({ isOther: false });
      this.props.onChange(value);
    }
  }

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
            value={this.state.isOther ? 'other' : value} />
        </span>
        {this.state.isOther && <SearchableDropdown
          readOnly={readOnly}
          name={`optionalHearingTime${this.state.index}`}
          placeholder="Select a time"
          options={TIME_OPTIONS}
          value={value}
          onChange={(option) => this.props.onChange(option ? option.value : null)}
          hideLabel />}
      </React.Fragment>
    );
  }
}
