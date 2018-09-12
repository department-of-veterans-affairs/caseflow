import React from 'react';
import PropTypes from 'prop-types';
import InlineForm from './InlineForm';
import DateSelector from './DateSelector';
import { formatDateStr } from '../util/DateUtil';
import { formatDate} from '../util/DateUtil';

export default class BasicDateRangeSelector extends React.Component {
  render() {
    let {startDateValue}=this.props;
    return <div>
      {this.props.messageLabel && <p><i>Please input a date range</i></p>}
      <InlineForm>
        <DateSelector
          name={this.props.startDateName}
          label={this.props.startDateLabel}
          value={this.props.startDateValue}
          onChange={this.props.onStartDateChange}
          type={"date"}
          // max="04-30-2001"
        />
        &nbsp;{this.props.messageLabel && 'to'}&nbsp;
        <DateSelector
          name={this.props.endDateName}
          label={this.props.endDateLabel}
          value={this.props.endDateValue}
          onChange={this.props.onEndDateChange}
          // max="04-30-2020"
          type="date"
        />
      </InlineForm>
    </div>;
  }
}

BasicDateRangeSelector.propTypes = {
  startDateName: PropTypes.string,
  startDateValue: PropTypes.string,
  endDateName: PropTypes.string,
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
  onEndDateChange: PropTypes.func,
  messageLabel: PropTypes.bool
};
