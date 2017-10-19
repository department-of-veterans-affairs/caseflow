import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';

import { NO_ISSUES_ON_APPEAL_MSG } from './constants';

const csvIssueLevels = (issue) => issue.levels ? issue.levels.join(', ') : '';

/**
 * Returns levels in a new line if formatLevelsInNewLine is true otherwise
 * the levels are returned as a comma seperated string in one line.
 */
const issueLevels = (issue, formatLevelsInNewLine) => (
  formatLevelsInNewLine ? issue.levels.map((level) =>
    <p className="issue-level" key={level}>{level}</p>) :
    csvIssueLevels(issue)
);

const issueTypeLabel = (issue) => issue.levels ? `${issue.type.label}:` : issue.type.label;

const IssueList = ({ appeal, formatLevelsInNewLine, className }) => (
  <div style={{ display: 'inline' }} >
    { _.isEmpty(appeal.issues) ?
      NO_ISSUES_ON_APPEAL_MSG :
      <ol className={className}>
      {appeal.issues.map((issue) =>
        <li key={`${issue.id}_${issue.vacols_sequence_id}`}><span>
          {issueTypeLabel(issue)} {issueLevels(issue, formatLevelsInNewLine)}
        </span></li>
      )}
      </ol>
    }
  </div>
);

IssueList.propTypes = {
  appeal: PropTypes.object.isRequired,
  formatLevelsInNewLine: PropTypes.bool
};

IssueList.defaultProps = {
  formatLevelsInNewLine: false
};

export default IssueList;
