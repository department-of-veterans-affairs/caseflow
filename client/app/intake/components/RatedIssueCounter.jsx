import React from 'react';

export default class RatedIssueCounter extends React.PureComponent {
  render = () =>
  <div className="cf-selected-issues">
    <span>{ this.props.selectedRatingCount }</span> rated issues
  </div>
};
