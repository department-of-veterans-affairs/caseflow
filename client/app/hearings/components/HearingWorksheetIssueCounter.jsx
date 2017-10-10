import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

class HearingWorksheetIssueCounter extends PureComponent {
  // Issue counter numbers issues across multiple streams
  // TODO renumber issues onDelete not just refersh
  render() {
    return <b>{this.props.issueCounter}</b>;
  }
}

HearingWorksheetIssueCounter.propTypes = {
  issueCounter: PropTypes.number.isRequired
};

export default connect()(HearingWorksheetIssueCounter);
