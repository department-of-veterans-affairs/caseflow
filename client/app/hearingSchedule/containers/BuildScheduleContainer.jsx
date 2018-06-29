import React from 'react';
import { connect } from 'react-redux';
import BuildSchedule from '../components/BuildSchedule';

export class BuildScheduleContainer extends React.Component {

  render() {
    return <BuildSchedule
      pastUploads={this.props.pastUploads}
    />;
  }
}

const mapStateToProps = (state) => ({
  pastUploads: state.pastUploads
});

export default connect(mapStateToProps)(BuildScheduleContainer);
