import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';

import { NO_ISSUES_ON_APPEAL_MSG } from './constants';
import { boldText } from '../queue/constants';
import StringUtil from '../util/StringUtil';

// todo: move to queue after Reader welcome gate deprecation
export default class IssueList extends React.PureComponent {
  getStyling = () => css({
    display: 'inline',
    '& .issue-level': {
      marginBottom: 0,
      marginTop: this.props.tightLevelStyling ? '0' : '0.5rem',
      '&.indented': {
        marginLeft: '20rem'
      }
    },
    '& .issue-label.indented': {
      marginLeft: '2rem'
    }
  });

  csvIssueLevels = (issue) => issue.levels ? issue.levels.join(', ') : '';

  /**
   * Returns levels in a new line if formatLevelsInNewLine is true otherwise
   * the levels are returned as a comma separated string in one line.
   */
  issueLevels = (issue, formatLevelsInNewLine = this.props.formatLevelsInNewLine) => {
    if (formatLevelsInNewLine) {
      const pClassName = `issue-level ${this.props.displayIssueProgram ? 'indented' : ''}`;

      return issue.levels.map((level) => <p className={pClassName} key={level}>{level}</p>);
    }

    return this.csvIssueLevels(issue);
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

  render = (appeal = this.props.appeal) => <div {...this.getStyling()}>
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

IssueList.propTypes = {
  appeal: PropTypes.object.isRequired,
  className: PropTypes.string,
  formatLevelsInNewLine: PropTypes.bool,
  displayIssueProgram: PropTypes.bool,
  displayLabels: PropTypes.bool,
  tightLevelStyling: PropTypes.bool
};

IssueList.defaultProps = {
  className: '',
  formatLevelsInNewLine: false,
  displayIssueProgram: false,
  displayLabels: false,
  tightLevelStyling: false
};
