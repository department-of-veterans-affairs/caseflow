import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import { boldText, ISSUE_PROGRAMS } from '../constants';

const minimalLeftPadding = css({ paddingLeft: '0.5rem' });
const noteMarginTop = css({ marginTop: '1.5rem' });
const issueMarginTop = css({ marginTop: '0.5rem' });
const issueLevelStyling = css({
  display: 'inline-block',
  width: '100%',
  marginLeft: '4.5rem'
});
const leftAlignTd = css({
  paddingLeft: 0,
  paddingRight: 0
});

export default class IssueListItem extends React.PureComponent {
  formatIdx = () => <td {...leftAlignTd} width="10px">
    {this.props.idx}.
  </td>;

  formatLevels = (issue) => issue.levels.map((level, idx) =>
    <div key={idx} {...issueMarginTop}>
      <span key={level} {...issueLevelStyling}>
        {idx === 1 ? _.last(issue.description) : level}
      </span>
    </div>);

  render = () => {
    const {
      issue,
      issuesOnly
    } = this.props;
    let issueContent = <span />;

    if (issuesOnly) {
      issueContent = <React.Fragment>
        {issue.type} {issue.levels.join(', ')}
      </React.Fragment>;
    } else {
      issueContent = <React.Fragment>
        <span {...boldText}>Program:</span> {ISSUE_PROGRAMS[issue.program]}
        <div {...issueMarginTop}><span {...boldText}>Issue:</span> {issue.type} {this.formatLevels(issue)}</div>
        <div {...noteMarginTop}>
          <span {...boldText}>Note:</span> {issue.note}
        </div>
      </React.Fragment>;
    }

    return <React.Fragment>
      {this.formatIdx()}
      <td {...minimalLeftPadding}>
        {issueContent}
      </td>
    </React.Fragment>;
  };
}

IssueListItem.propTypes = {
  issue: PropTypes.object.isRequired,
  issuesOnly: PropTypes.bool,
  idx: PropTypes.number.isRequired
};

IssueListItem.defaultProps = {
  issuesOnly: false
};
