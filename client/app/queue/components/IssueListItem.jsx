import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import LegacyIssueListItem from './LegacyIssueListItem';

const minimalLeftPadding = css({ paddingLeft: '0.5rem' });
const leftAlignTd = css({
  paddingLeft: 0,
  paddingRight: 0
});

export default class IssueListItem extends React.PureComponent {
  formatIdx = () => <td {...leftAlignTd} width="10px">
    {this.props.idx}.
  </td>;

  render = () => <React.Fragment>
    {this.formatIdx()}
    <td {...minimalLeftPadding}>
      {this.props.issue.description}
    </td>
  </React.Fragment>;
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
