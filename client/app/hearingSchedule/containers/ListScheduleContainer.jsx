import React from 'react';
import { connect } from 'react-redux';
import ListSchedule from '../components/ListSchedule';
import { onReceiveHearingSchedule } from '../actions'

export class ListScheduleContainer extends React.Component {
  componentDidMount = () => {

  }

  render() {
    return <ListSchedule
      hearingSchedule={this.props.hearingSchedule}
    />;
  }
}

const mapStateToProps = (state) => ({
  hearingSchedule: state.hearingSchedule
});

export default connect(mapStateToProps)(ListScheduleContainer);
