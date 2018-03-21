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
      issue: {
        program,
        type,
        levels,
        description,
        codes: [
          , ,
          isslev1,
          isslev2,
          isslev3
        ]
      }
    } = this.props;
    const issueLevels = [];
    const vacolsIssue = ISSUE_INFO[program].issue[type];

    if (!vacolsIssue) {
      return levels;
    }

    const issueLevel1 = _.get(vacolsIssue.levels, isslev1);
    const issueLevel2 = _.get(issueLevel1, `levels[${isslev2}]`);
    const issueLevel3 = _.get(issueLevel2, `levels[${isslev3}]`);

    if (issueLevel1) {
      issueLevels.push(issueLevel1.description);

      if (issueLevel2 && issueLevel2.levels) {
        issueLevels.push(issueLevel2.description);

        issueLevels.push(issueLevel3 ? issueLevel3.description : _.last(description));
      } else {
        issueLevels.push(_.last(description));
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
