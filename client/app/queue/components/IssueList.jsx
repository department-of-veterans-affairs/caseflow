import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import { NO_ISSUES_ON_APPEAL_MSG } from '../../reader/constants';
import { boldText } from '../constants';
import StringUtil from '../../util/StringUtil';

const tableContainerStyling = css({ width: '55rem' });
const tableStyling = css({
  '& td': {
    verticalAlign: 'top',
    border: 'none',
    paddingTop: 0
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
const programColumnWidth = css({ width: '20rem' });
const noteMarginTop = css({ marginTop: '1.5rem' });
const issueMarginTop = css({ marginTop: '0.5rem' });

export default class IssueList extends React.PureComponent {
  issueLevels = (issue) => issue.levels.map((level, idx) => <div key={idx} {...issueMarginTop}>
    <span key={level} {...issueLevelStyling}>
      {idx === 1 ? issue.levels_with_codes[idx] : level}
    </span>
  </div>);

  issueTypeLabel = (issue) => <div>
    <span {...boldText}>Issue:</span> {issue.type}
  </div>;

  render = () => {
    const {
      appeal
    } = this.props;
    let listContent = <tr>
      <td>{NO_ISSUES_ON_APPEAL_MSG}</td>
    </tr>;

    if (appeal.issues.length) {
      listContent = <React.Fragment>
        {appeal.issues.map((issue, idx) => <tr key={`${issue.id}_${issue.vacols_sequence_id}`}>
          <td {...leftAlignTd}>
            <div {...programColumnWidth}>
              {idx + 1}. <span {...boldText}>Program:</span> {StringUtil.titleCase(issue.program)}
            </div>
          </td>
          <td>
            {this.issueTypeLabel(issue)} {this.issueLevels(issue)}
            <div {...noteMarginTop}>
              <span {...boldText}>Note:</span> {issue.note}
            </div>
          </td>
        </tr>)}
      </React.Fragment>;
    }

    return <div {...tableContainerStyling}>
      <table {...tableStyling}>
        <tbody>
          {listContent}
        </tbody>
      </table>
    </div>;
  };
}

IssueList.propTypes = {
  appeal: PropTypes.shape({
    issues: PropTypes.array
  }).isRequired
};
