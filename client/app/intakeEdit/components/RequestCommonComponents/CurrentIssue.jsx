import React from 'react';
import PropTypes from 'prop-types';
import { formatDateStr } from 'app/util/DateUtil';

export const CurrentIssue = ({ currentIssue }) => {
  return (
    <div style={{ marginBottom: '2.4rem' }}>
      <h2 style={{ marginBottom: '0px' }}>Current issue</h2>
      <strong>Issue type: </strong>{currentIssue.category}<br />
      <strong>Decision date: </strong>{formatDateStr(currentIssue.decisionDate)}<br />
      <strong>Issue description: </strong>{currentIssue.nonRatingIssueDescription}<br />
    </div>
  );
};

CurrentIssue.propTypes = {
  currentIssue: PropTypes.object,
  onCancel: PropTypes.func,
};

export default CurrentIssue;
