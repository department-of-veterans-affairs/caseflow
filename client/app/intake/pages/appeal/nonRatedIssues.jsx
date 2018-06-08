import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { addNonRatedIssue, setIssueCategory, setIssueDescription } from '../../actions/common';
import { NonRatedIssueUnconnected, AddIssueButtonUnconnected } from '../../components/NonRatedIssue';
import _ from 'lodash';

class NonRatedIssuesUnconnected extends React.PureComponent {
  render() {
    const { nonRatedIssues } = this.props;

    const nonRatedIssuesSection = _.map(nonRatedIssues, (issue, issueId) => {
      return (
        <NonRatedIssue key={issueId} id={issueId} category={issue.category} description={issue.description} />
      );
    });

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
}

const NonRatedIssues = connect(
  ({ appeal }) => ({
    nonRatedIssues: appeal.nonRatedIssues
  })
)(NonRatedIssuesUnconnected);

export default NonRatedIssues;

const NonRatedIssue = connect(
  ({ appeal }) => ({
    nonRatedIssues: appeal.nonRatedIssues
  }),
  (dispatch) => bindActionCreators({
    setIssueCategory,
    setIssueDescription
  }, dispatch)
)(NonRatedIssueUnconnected);

const AddIssueButton = connect(
  ({ appeal }) => ({ nonRatedIssues: appeal.nonRatedIssues }),
  (dispatch) => bindActionCreators({
    addNonRatedIssue
  }, dispatch)
)(AddIssueButtonUnconnected);
