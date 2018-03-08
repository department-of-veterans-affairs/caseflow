import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import { NO_ISSUES_ON_APPEAL_MSG } from '../../reader/constants';
import { boldText } from '../constants';
import StringUtil from '../../util/StringUtil';

const tableContainerStyling = (fluid) => css({
  width: fluid ? '100%' : '55rem',
  '> table': {
    marginTop: fluid ? '0rem' : '1rem',
    marginBottom: '1rem',
    '& td': {
      verticalAlign: 'top',
      border: 'none',
      paddingTop: 0,
      backgroundColor: 'inherit'
    }
  }
});
const issueLevelStyling = css({
  display: 'inline-block',
  width: '100%',
  marginLeft: '4.5rem'
});
const leftAlignTd = css({
  paddingLeft: 0,
  paddingRight: 0
});
const minimalLeftPadding = css({ paddingLeft: '0.5rem' });
const noteMarginTop = css({ marginTop: '1.5rem' });
const issueMarginTop = css({ marginTop: '0.5rem' });
const bottomBorder = (singleIssue) => css({ borderBottom: singleIssue ? 'none !important' : '' });

export default class IssueList extends React.PureComponent {
  issueLevels = (issue) => issue.levels.map((level, idx) => <div key={idx} {...issueMarginTop}>
    <span key={level} {...issueLevelStyling}>
      {idx === 1 ? _.last(issue.description) : level}
    </span>
  </div>);

  formatIssueProgram = (issue) => {
    const programWords = StringUtil.titleCase(issue.program).split(' ');
    const acronyms = ['vba', 'bva', 'vre', 'nca'];

    return programWords.map((word) =>
      acronyms.includes(word.toLowerCase()) ? word.toUpperCase() : word
    ).join(' ');
  };

  getIssues = () => {
    const {
      appeal,
      issuesOnly,
      idxToDisplay,
    } = this.props;
    const singleIssue = appeal.issues.length === 1;

    if (!appeal.issues.length) {
      return <tr>
        <td>{NO_ISSUES_ON_APPEAL_MSG}</td>
      </tr>;
    }

    if (issuesOnly) {
      return <React.Fragment>{appeal.issues.map((issue, idx) =>
        <tr key={`${issue.id}_${issue.vacols_sequence_id}`} {...bottomBorder(singleIssue)}>
          <td {...leftAlignTd}>
            {idxToDisplay || (idx + 1)}.
          </td>
          <td {...minimalLeftPadding}>
            {issue.type} {issue.levels.join(', ')}
          </td>
        </tr>)
      }</React.Fragment>;
    }

    return <React.Fragment>{appeal.issues.map((issue, idx) =>
      <tr key={`${issue.id}_${issue.vacols_sequence_id}`} {...bottomBorder(singleIssue)}>
        <td {...leftAlignTd} width="10px">
          {idx + 1}.
        </td>
        <td>
          <span {...boldText}>Program:</span> {this.formatIssueProgram(issue)}
          <div{...issueMarginTop}><span {...boldText}>Issue:</span> {issue.type} {this.issueLevels(issue)}</div>
          <div {...noteMarginTop}>
            <span {...boldText}>Note:</span> {issue.note}
          </div>
        </td>
      </tr>)
    }</React.Fragment>;
  };

  render = () => <div {...tableContainerStyling(this.props.issuesOnly)}>
    <table>
      <tbody>
        {this.getIssues()}
      </tbody>
    </table>
  </div>;
}

IssueList.propTypes = {
  appeal: PropTypes.shape({
    issues: PropTypes.array
  }).isRequired,
  issuesOnly: PropTypes.bool,
  idxToDisplay: PropTypes.number
};

IssueList.defaultProps = {
  issuesOnly: false
};
