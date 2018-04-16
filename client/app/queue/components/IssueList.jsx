import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import IssueListItem from './IssueListItem';
import { NO_ISSUES_ON_APPEAL_MSG } from '../../reader/constants';

const tableContainerStyling = (fluid) => css({
  width: fluid ? '100%' : '75rem',
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
const bottomBorder = (singleIssue) => css({
  borderBottom: singleIssue ? 'none !important' : ''
});

export default class IssueList extends React.PureComponent {
  getIssues = () => {
    const {
      appeal: { issues }
    } = this.props;
    const singleIssue = issues.length === 1;

    if (!issues.length) {
      return <tr>
        <td>{NO_ISSUES_ON_APPEAL_MSG}</td>
      </tr>;
    }

    return <React.Fragment>{issues.map((issue, idx) =>
      <tr key={`${issue.id}_${issue.vacols_sequence_id}`} {...bottomBorder(singleIssue)}>
        <IssueListItem issue={issue} idx={this.props.idxToDisplay || (idx + 1)} {...this.props} />
      </tr>)
    }</React.Fragment>;
  };

  render = () => <div {...tableContainerStyling(this.props.issuesOnly || this.props.stretchToFullWidth)}>
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
  idxToDisplay: PropTypes.number,
  stretchToFullWidth: PropTypes.bool
};

IssueList.defaultProps = {
  issuesOnly: false,
  stretchToFullWidth: false
};
