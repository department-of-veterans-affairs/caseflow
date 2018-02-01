import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';

import { NO_ISSUES_ON_APPEAL_MSG } from '../reader/constants';
import { boldText } from './constants';
import StringUtil from '../util/StringUtil';

const inlineDisplay = css({
  display: 'inline',
  '& .issue-level': {
    marginBottom: 0,
    marginTop: '0.5rem',
    '&.indented': {
      marginLeft: '20rem'
    }
  },
  '& .issue-label.indented': {
    marginLeft: '2rem'
  }
});

// todo: rename to IssueList after Reader welcome gate deprecation
export default class QueueIssueList extends React.PureComponent {
  csvIssueLevels = (issue) => issue.levels ? issue.levels.join(', ') : '';

  issueLevels = (issue, formatLevelsInNewLine = this.props.formatLevelsInNewLine) => {
    if (formatLevelsInNewLine) {
      const pClassName = `issue-level ${this.props.displayIssueProgram ? 'indented' : ''}`;

      return issue.levels.map((level) => <p className={pClassName} key={level}>{level}</p>);
    }

    return this.csvIssueLevels();
  };

  issueTypeLabel = (issue) => {
    const label = issue.type;

    if (this.props.displayLabels) {
      return <span className={`issue-label ${this.props.displayIssueProgram ? 'indented' : ''}`}>
        <span {...boldText}>Issue:</span> {label}
      </span>;
    }

    return label;
  };

  render = (appeal = this.props.appeal) => <div {...inlineDisplay}>
    {_.isEmpty(appeal.issues) ?
      NO_ISSUES_ON_APPEAL_MSG :
      <ol className={this.props.className}>
        {appeal.issues.map((issue) =>
          <li key={`${issue.id}_${issue.vacols_sequence_id}`}>
            {this.props.displayIssueProgram && <span>
              <span {...boldText}>Program:</span> {StringUtil.titleCase(issue.program)}
            </span>}
            <span>
              {this.issueTypeLabel(issue)} {this.issueLevels(issue)}
            </span>
          </li>
        )}
      </ol>
    }
  </div>;
}

QueueIssueList.propTypes = {
  appeal: PropTypes.object.isRequired,
  className: PropTypes.string,
  formatLevelsInNewLine: PropTypes.bool,
  displayIssueProgram: PropTypes.bool,
  displayLabels: PropTypes.bool
};

QueueIssueList.defaultProps = {
  className: '',
  formatLevelsInNewLine: false,
  displayIssueProgram: false,
  displayLabels: false
};
