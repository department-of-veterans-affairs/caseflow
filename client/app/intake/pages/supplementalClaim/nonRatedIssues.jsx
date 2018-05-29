import React from 'react';
import Button from '../../../components/Button';

export default class NonRatedIssues extends React.PureComponent {
  render = () => <div className="cf-non-rated-issues">
    <h2>Enter other issue(s) for review</h2>
    <p>
      If the Veteran included any additional issues you cannot find in the list above,
      please note them below. Otherwise, leave the section blank.
    </p>
    <Button
      name="add-issue"
      legacyStyling={false}
    >
      + Add issue
    </Button>
  </div>;
}
