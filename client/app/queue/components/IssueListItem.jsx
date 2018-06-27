import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';
import LegacyIssueListItem from './LegacyIssueListItem';

import {
  getIssueProgramDescription,
  getIssueTypeDescription,
  getIssueDiagnosticCodeLabel
} from '../utils';
import { boldText } from '../constants';
import ISSUE_INFO from '../../../constants/ISSUE_INFO.json';
import VACOLS_DISPOSITIONS_BY_ID from '../../../constants/VACOLS_DISPOSITIONS_BY_ID.json';

const minimalLeftPadding = css({ paddingLeft: '0.5rem' });
const leftAlignTd = css({
  paddingLeft: 0,
  paddingRight: 0
});

export default class IssueListItem extends React.PureComponent {
  formatIdx = () => <td {...leftAlignTd} width="10px">
    {this.props.idx}.
  </td>;

  render = () => {
    // Fall back on legacy issue list item if this is a legacy issues.
    if (this.props.issue.program) {
      return <LegacyIssueListItem {...this.props} />
    }

    const description = this.props.issue.description;

    return <React.Fragment>
      {this.formatIdx()}
      <td {...minimalLeftPadding}>
        {description}
      </td>
    </React.Fragment>;
  };
}

IssueListItem.propTypes = {
  issue: PropTypes.object.isRequired,
  issuesOnly: PropTypes.bool,
  idx: PropTypes.number.isRequired,
  showDisposition: PropTypes.bool
};

IssueListItem.defaultProps = {
  issuesOnly: false,
  showDisposition: true
};
