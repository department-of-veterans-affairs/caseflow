import React from 'react';
import PropTypes from 'prop-types';
import { formatDateStr } from 'app/util/DateUtil';

export const CurrentIssue = ({ currentIssue, title = 'Current issue' }) => {
  return (
    <div style={{ marginBottom: '2.4rem' }}>
      <h2 style={{ marginBottom: '0px' }}>{title}</h2>
      <strong>Issue type: </strong>{currentIssue.category || currentIssue.nonratingIssueCategory }<br />
      <strong>Decision date: </strong>{formatDateStr(currentIssue.decisionDate)}<br />
      <strong>Issue description: </strong>{currentIssue.nonRatingIssueDescription ||
        currentIssue.nonratingIssueDescription}<br />
    </div>
  );
};

CurrentIssue.propTypes = {
  currentIssue: PropTypes.object,
  onCancel: PropTypes.func,
  title: PropTypes.string
};

export default CurrentIssue;
