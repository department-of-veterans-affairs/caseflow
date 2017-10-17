import React from 'react';
import PropTypes from 'prop-types';

const IssueList = ({ appeal }) => (
  <div>
    {appeal.issues.map((issue) =>
      <li key={`${issue.id}_${issue.vacols_sequence_id}`}><span>
        {issue.type.label}: {issue.levels ? issue.levels.join(', ') : ''}
      </span></li>
    )}
  </div>
);

IssueList.propTypes = {
  appeal: PropTypes.object
};

export default IssueList;
