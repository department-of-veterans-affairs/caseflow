import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';

import { NO_ISSUES_ON_APPEAL_MSG } from './constants';
import { boldText } from '../queue/constants';
import StringUtil from '../util/StringUtil';

const issueListStyle = css({
  display: 'inline'
});
const labelStyle = (displayIssueProgram) => css({
  marginLeft: displayIssueProgram ? '2rem' : null
});
const issueLevelStyle = (displayIssueProgram) => css({
  marginBottom: 0,
  marginTop: 0,
  marginLeft: displayIssueProgram ? '20rem' : null
});
const issueNoteStyle = css({
  marginTop: '1rem',
  marginLeft: '20rem'
});

// todo: move to queue after Reader welcome gate deprecation
export default class IssueList extends React.PureComponent {

  csvIssueLevels = (issue) => issue.levels ? issue.levels.join(', ') : '';

  /**
   * Returns levels in a new line if formatLevelsInNewLine is true otherwise
   * the levels are returned as a comma separated string in one line.
   */
  issueLevels = (issue, formatLevelsInNewLine = this.props.formatLevelsInNewLine) => {
    if (formatLevelsInNewLine) {
      const { displayIssueProgram } = this.props;

      return issue.levels.map((level, idx) =>
        <p {...issueLevelStyle(displayIssueProgram)} key={level}>
          {displayIssueProgram && idx === 1 ? `${issue.codes[3]} - ${level}` : level}
        </p>);
    }

    return this.csvIssueLevels(issue);
  };

  issueTypeLabel = (issue) => {
    const label = issue.type;

    if (this.props.displayLabels) {
      return <span {...labelStyle(this.props.displayIssueProgram)}>
        <span {...boldText}>Issue:</span> {label}
      </span>;
    }

    return label;
  };

  render = () => {
    const appeal = this.props.appeal;
    let listContent = NO_ISSUES_ON_APPEAL_MSG;

    if (!_.isEmpty(appeal.issues)) {
      listContent = <ol className={this.props.className}>
        {appeal.issues.map((issue) =>
          <li key={`${issue.id}_${issue.vacols_sequence_id}`}>
            {this.props.displayIssueProgram && <span>
              <span {...boldText}>Program:</span> {StringUtil.titleCase(issue.program)}
            </span>}
            <span>
              {this.issueTypeLabel(issue)} {this.issueLevels(issue)}
            </span>
            {this.props.displayIssueNote && issue.note && <div {...issueNoteStyle}>
              <span {...boldText}>Note:</span> {issue.note}
            </div>}
          </li>
        )}
      </ol>;
    }

    return <div {...issueListStyle}>
      {listContent}
    </div>;
  };
}

IssueList.propTypes = {
  appeal: PropTypes.object.isRequired,
  className: PropTypes.string,
  formatLevelsInNewLine: PropTypes.bool,
  displayIssueProgram: PropTypes.bool,
  displayIssueNote: PropTypes.bool,
  displayLabels: PropTypes.bool
};

IssueList.defaultProps = {
  className: '',
  formatLevelsInNewLine: false,
  displayIssueProgram: false,
  displayIssueNote: false,
  displayLabels: false
};
