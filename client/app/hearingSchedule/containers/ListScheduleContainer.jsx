import React from 'react';
import { connect } from 'react-redux';
import ListSchedule from '../components/ListSchedule';
import { onViewStartDateChange, onViewEndDateChange } from '../actions';
import { bindActionCreators } from 'redux';

export class ListScheduleContainer extends React.Component {

  render() {
    return <ListSchedule
      hearingSchedule={this.props.hearingSchedule}
      startDateValue={this.props.startDate}
      startDateChange={this.props.onViewStartDateChange}
      endDateValue={this.props.endDate}
      endDateChange={this.props.onViewEndDateChange}
    />;
  }
}

const mapStateToProps = (state) => ({
  hearingSchedule: state.hearingSchedule,
  startDate: state.viewStartDate,
  endDate: state.viewEndDate
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onViewStartDateChange,
  onViewEndDateChange
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(ListScheduleContainer);
