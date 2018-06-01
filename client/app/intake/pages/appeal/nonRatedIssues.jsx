import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { addNonRatedIssue, setNonRatedIssue } from '../../actions/common';
import Button from '../../../components/Button';
import NonRatedIssue from '../../components/NonRatedIssue'
import ISSUE_CATEGORIES from '../../constants.js'
import _ from 'lodash';

class NonRatedIssues extends React.PureComponent {
  render() {

    const nonRatedIssuesSection = () => {
      for (issueId in this.props.nonRatedIssues) {
        return <NonRatedIssue
        key={issueId}
        />
      }
    }

    return <div className="cf-non-rated-issues">
      <h2>Enter other issue(s) for review</h2>
      <p>
      If the Veteran included any additional issues you cannot find in the list above,
      please note them below. Otherwise, leave the section blank.
      </p>
      <div>
        { nonRatedIssuesSection }
      </div>
      <AddIssueButton />
    </div>;
  }
};

const NonRatedIssuesConnected = connect(
  ({ appeal }) => ({
    appeal
  }),
  (dispatch) => bindActionCreators({
    setNonRatedIssue
  }, dispatch)
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
