import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

class HearingWorksheetIssueCounter extends PureComponent {

  render() {
    let { issueCounter } = this.props;

    return <b>{issueCounter}</b>;
  }
}
HearingWorksheetIssueCounter.propTypes = {
  issueCounter: PropTypes.number.isRequired
};


export default connect()(HearingWorksheetIssueCounter);
