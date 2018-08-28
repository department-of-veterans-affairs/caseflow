import React from 'react';
import PropTypes from 'prop-types';
import InlineForm from './InlineForm';
import DateSelector from './DateSelector';
import { css } from 'glamor';


const dateSeparator = css({
  paddingLeft: '2rem',
  display: 'inline-block'
});

const hearingSchedStyling = css({
  paddingLeft: '5rem'
});

export default class BasicDateRangeSelector extends React.Component {
  render() {
    return <div>
      {/* {this.props.messageLabel && <p><i>Please input a date range</i></p>} */}
      <InlineForm>
        <DateSelector {...hearingSchedStyling}
          name={this.props.startDateName}
          label="Start Date"
          value={this.props.startDateValue}
          onChange={this.props.onStartDateChange}
          type="date"
          {...dateSeparator}
        />
        {/* &nbsp;{this.props.messageLabel && 'to'}&nbsp; */}
        <div {...dateSeparator} ></div> 
        <DateSelector
          name={this.props.endDateName}
          label= "End Date"
          value={this.props.endDateValue}
          onChange={this.props.onEndDateChange}
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
