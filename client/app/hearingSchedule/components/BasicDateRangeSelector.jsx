import React from 'react';
import PropTypes from 'prop-types';
import InlineForm from '../../components/InlineForm';
import DateSelector from '../../components/DateSelector';

export default class BasicDateRangeSelector extends React.Component {
  render() {
    return <div>
      <p><i>Please enter a date range</i></p>
      <InlineForm>
        <DateSelector
          name="startDate"
          label={this.props.startDateLabel}
          value={this.props.startDateValue}
          onChange={this.props.onStartDateChange}
        />
        &nbsp;to&nbsp;
        <DateSelector
          name="endDate"
          label={this.props.endDateLabel}
          value={this.props.endDateValue}
          onChange={this.props.onEndDateChange}
        />
      </InlineForm>
    </div>;
  }
}

BasicDateRangeSelector.propTypes = {
  startDateValue: PropTypes.string,
  endDateValue: PropTypes.string,
  startDateLabel: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.bool
  ]),
  endDateLabel: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.bool
  ]),
  onStartDateChange: PropTypes.func,
  onEndDateChange: PropTypes.func
};
