import React from 'react';
import pluralize from 'pluralize';

export default class IssueCounter extends React.PureComponent {
  render = () =>
    <div className="cf-selected-issues">
      <span>{ this.props.issueCount }</span> { pluralize('issue', this.props.issueCount) }
    </div>
}
