import React from 'react';
import PropTypes from 'prop-types';
import InlineForm from '../../components/InlineForm';
import DateSelector from '../../components/DateSelector';

export default class UploadDateSelector extends React.Component {
  render() {
    return <div>
      <p><i>Please input a date range</i></p>
      <InlineForm>
        <DateSelector
          name="Start Date"
          label={false}
          value={this.props.startDate}
          onChange={this.props.onStartDateChange}
        />
        &nbsp;to&nbsp;
        <DateSelector
          name="End Date"
          label={false}
          value={this.props.endDate}
          onChange={this.props.onEndDateChange}
        />
      </InlineForm>
    </div>;
  }
}

UploadDateSelector.propTypes = {
  startDate: PropTypes.string,
  endDate: PropTypes.string,
  onStartDateChange: PropTypes.func,
  onEndDateChange: PropTypes.func
};
