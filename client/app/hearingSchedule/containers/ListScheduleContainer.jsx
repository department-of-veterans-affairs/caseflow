import React from 'react';
import { connect } from 'react-redux';
import ListSchedule from '../components/ListSchedule';

export class ListScheduleContainer extends React.Component {

  render() {
    return <ListSchedule
      pastUploads={this.props.pastUploads}
    />;
  }
}

const mapStateToProps = (state) => ({
  pastUploads: state.pastUploads
});

export default connect(mapStateToProps)(ListScheduleContainer);
