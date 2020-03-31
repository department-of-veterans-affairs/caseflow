import React from 'react';
import PropTypes from 'prop-types';
import Alert from '../../components/Alert';
import COPY from '../../../COPY';

class UnidentifiedIssueAlert extends React.Component {
  render() {
    const unidentifiedIssues = this.props.unidentifiedIssues;

    return <Alert type="warning">
      <h2>Unidentified issue</h2>
      <p>{COPY.UNIDENTIFIED_ALERT}</p>
      {unidentifiedIssues.map((ri, i) => <p className="cf-red-text" key={`unidentified-alert-${i}`}>
        Unidentified issue: no issue matched for requested "{ri.description}"
      </p>)}
    </Alert>;
  }
}

UnidentifiedIssueAlert.propTypes = {
  unidentifiedIssues: PropTypes.arrayOf(PropTypes.object)
};

export default UnidentifiedIssueAlert;
