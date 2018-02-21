import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import { NO_ISSUES_ON_APPEAL_MSG } from '../../reader/constants';
import { boldText } from '../constants';
import StringUtil from '../../util/StringUtil';

const tableContainerStyling = (issuesOnly) => css({
  width: issuesOnly ? '100%' : '55rem'
});
const tableStyling = css({
  marginTop: '1rem',
  marginBottom: '1rem',
  '& td': {
    verticalAlign: 'top',
    border: 'none',
    paddingTop: 0,
    backgroundColor: 'inherit'
  }
});
const issueLevelStyling = css({
  display: 'inline-block',
  width: '100%'
});
const leftAlignTd = css({
  paddingLeft: 0,
  paddingRight: 0
});
const minimalLeftPadding = css({ paddingLeft: '0.5rem' });
const noteMarginTop = css({ marginTop: '1.5rem' });
const issueMarginTop = css({ marginTop: '0.5rem' });

export default class IssueList extends React.PureComponent {
  issueLevels = (issue) => issue.levels.map((level, idx) => <div key={idx} {...issueMarginTop}>
    <span key={level} {...issueLevelStyling}>
      {idx === 1 ? _.last(issue.description) : level}
    </span>
  </div>);

  issueTypeLabel = (issue) => <React.Fragment>
    <span {...boldText}>Issue:</span> {issue.type}
  </React.Fragment>;

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
      issuesOnly
    } = this.props;

    if (!appeal.issues.length) {
      return <tr>
        <td>{NO_ISSUES_ON_APPEAL_MSG}</td>
      </tr>;
    }

    if (issuesOnly) {
      return <React.Fragment>
        {appeal.issues.map((issue, idx) => <tr key={`${issue.id}_${issue.vacols_sequence_id}`}>
          <td {...leftAlignTd}>
            {idx + 1}.
          </td>
          <td {...minimalLeftPadding}>
            {issue.type} {issue.levels.join(', ')}
          </td>
        </tr>)}
      </React.Fragment>;
    }

    return <React.Fragment>
      {appeal.issues.map((issue, idx) => <tr key={`${issue.id}_${issue.vacols_sequence_id}`}>
        <td {...leftAlignTd} width="210px">
          {idx + 1}. <span {...boldText}>Program:</span> {this.formatIssueProgram(issue)}
        </td>
        <td>
          {this.issueTypeLabel(issue)} {this.issueLevels(issue)}
          <div {...noteMarginTop}>
            <span {...boldText}>Note:</span> {issue.note}
          </div>
        </td>
      </tr>)}
    </React.Fragment>;

  };

  render = () => <div {...tableContainerStyling(this.props.issuesOnly)}>
    <table {...tableStyling}>
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
  issuesOnly: PropTypes.bool
};

IssueList.defaultProps = {
  issuesOnly: false
};
