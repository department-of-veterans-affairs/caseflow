import React from 'react';
import { TIME_OPTIONS } from '../../../hearings/constants/constants';
import { css } from 'glamor';
import RadioField from '../../../components/RadioField';
import SearchableDropdown from '../../../components/SearchableDropdown';

const formStyling = css({
  '& .cf-form-radio-option:not(:last-child)': {
    display: 'inline-block',
    marginRight: '25px'
  },
  marginBottom: 0
});

export default class HearingTime extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      isOther: false
    };
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
    const { errorMessage, value } = this.props;

    return (
      <React.Fragment>
        <span {...formStyling}>
          <RadioField
            errorMessage={errorMessage}
            name="time"
            label="Time"
            strongLabel
            options={this.getTimeOptions()}
            onChange={this.onRadioChange}
            value={this.state.isOther ? 'other' : value} />
        </span>
        {this.state.isOther && <SearchableDropdown
          name="optionalTime"
          placeholder="Select a time"
          options={TIME_OPTIONS}
          value={value}
          onChange={this.props.onChange}
          hideLabel />}
      </React.Fragment>
    );
  }
}
