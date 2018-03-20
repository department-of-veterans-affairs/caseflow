import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import { boldText, ISSUE_INFO } from '../constants';

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

  formatLevels = () => {
    const {
      issue,
      issue: {
        description,
        codes: [
          , ,
          isslev1,
          isslev2,
          isslev3
        ]
      }
    } = this.props;
    const vacolsIssue = ISSUE_INFO[issue.program].issue[issue.type];
    const issueLevels = [];

    if (vacolsIssue.levels && isslev1 in vacolsIssue.levels) {
      const issueLevel1 = vacolsIssue.levels[isslev1];
      issueLevels.push(issueLevel1);

      if (isslev2) {
        if (!issueLevel1.levels) {
          // diagnostic code, use description (code w/text)
          issueLevels.push(_.last(description));
        } else {
          const issueLevel2 = issueLevel1.levels[isslev2];
          issueLevels.push(issueLevel2);

          if (isslev3) {
            if (!issueLevel2.levels) {
              // diagnostic code
              issueLevels.push(_.last(description));
            } else {
              const issueLevel3 = issueLevel2.levels[isslev3];
              issueLevels.push(issueLevel3);
            }
          }
        }
      }
    }

    return issueLevels.map((code, idx) => <div key={idx} {...issueMarginTop}>
      <span key={code} {...issueLevelStyling}>
        {_.get(code, 'description', code)}
      </span>
    </div>);
  };

  getIssue = () => {
    const {
      issue: { program, type }
    } = this.props;
    const vacolsIssue = _.get(ISSUE_INFO[program].issue, type);

    return _.get(vacolsIssue, 'description');
  };

  render = () => {
    const {
      issue: {
        type,
        levels,
        note,
        program
      },
      issuesOnly
    } = this.props;
    let issueContent = <span />;

    if (issuesOnly) {
      issueContent = <React.Fragment>
        {type} {levels.join(', ')}
      </React.Fragment>;
    } else {
      issueContent = <React.Fragment>
        <span {...boldText}>Program:</span> {ISSUE_INFO[program].description}
        <div {...issueMarginTop}>
          <span {...boldText}>Issue:</span> {this.getIssue()} {this.formatLevels()}
        </div>
        <div {...noteMarginTop}>
          <span {...boldText}>Note:</span> {note}
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
