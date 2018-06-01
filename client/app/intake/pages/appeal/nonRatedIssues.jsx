import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { addNonRatedIssue } from '../../actions/common';
import Button from '../../../components/Button';
import NonRatedIssue from '../../components/NonRatedIssue'
import ISSUE_CATEGORIES from '../../constants.js'
import _ from 'lodash';

class NonRatedIssues extends React.PureComponent {
  render() {
    return <div className="cf-non-rated-issues">
      <h2>Enter other issue(s) for review</h2>
      <p>
      If the Veteran included any additional issues you cannot find in the list above,
      please note them below. Otherwise, leave the section blank.
      </p>
      <div>
        <NonRatedIssue key="0" issueId="0" />
      </div>
      <AddIssueButton />
    </div>;
  }
};

const NonRatedIssuesConnected = connect(
  ({ appeal }) => ({
    appeal
  })
)(NonRatedIssues);

export default NonRatedIssuesConnected;

class AddIssueButtonUnconnected extends React.PureComponent {
  render = () =>
    <Button
      name="add-issue"
      onClick={this.props.addNonRatedIssue}
      legacyStyling={false}
    >
    + Add issue
    </Button>;
}

export const AddIssueButton = connect(
  ({ appeal }) => ({ nonRatedIssues: appeal.nonRatedIssues }),
  (dispatch) => bindActionCreators({
    addNonRatedIssue
  }, dispatch))
(AddIssueButtonUnconnected);
