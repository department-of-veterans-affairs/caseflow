import React from 'react';
import moment from 'moment';
import { css } from 'glamor';
import RadioField from '../../../components/RadioField';
import SearchableDropdown from '../../../components/SearchableDropdown';
import { TIME_OPTIONS } from '../../../hearings/constants/constants';
import _ from 'lodash';

export const getAssignHearingTime = (time, day) => {

  return {
    // eslint-disable-next-line id-length
    h: time.split(':')[0],
    // eslint-disable-next-line id-length
    m: time.split(':')[1],
    offset: moment.tz(day.hearingDate, day.timezone || 'America/New_York').format('Z')
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

  getTimeOptions = () => {
    const { regionalOffice } = this.props;

    if (regionalOffice === 'C') {
      return [
        { displayText: '9:00 am',
          value: '9:00' },
        { displayText: '1:00 pm',
          value: '13:00' },
        { displayText: 'Other',
          value: 'other' }
      ];
    }

    return [
      { displayText: '8:30 am',
        value: '8:30' },
      { displayText: '12:30 pm',
        value: '12:30' },
      { displayText: 'Other',
        value: 'other' }
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
            disabled={readOnly}
            errorMessage={errorMessage}
            name={`hearingTime${this.state.index}`}
            label="Time"
            strongLabel
            options={this.getTimeOptions()}
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
