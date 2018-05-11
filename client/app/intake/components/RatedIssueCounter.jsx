import React from 'react';
import pluralize from 'pluralize';

export default class RatedIssueCounter extends React.PureComponent {
  render = () =>
    <div className="cf-selected-issues">
      <span>{ this.props.selectedRatingCount }</span> rated { pluralize('issue', this.props.selectedRatingCount) }
    </div>
}
