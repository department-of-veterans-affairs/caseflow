import React from 'react';
import { getIntakeStatus } from '../../selectors';
import CancelButton from '../../components/CancelButton';
import Checkbox from '../../../components/Checkbox';
import Table from '../../../components/Table';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, RAMP_INTAKE_STATES } from '../../constants';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setIssueSelected, setHasIneligibleIssue, setOutsideCaseflowStepsConfirmed }
  from '../../actions/rampRefiling';
import _ from 'lodash';

class Finish extends React.PureComponent {
  onCheckIssue = (issueId) => (checked) => this.props.setIssueSelected(issueId, checked)

  render() {
    const {
      rampRefilingStatus,
      issues,
      hasIneligibleIssue,
      outsideCaseflowStepsConfirmed
    } = this.props;

    switch (rampRefilingStatus) {
    case RAMP_INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case RAMP_INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    const issueColumns = [
      {
        header: 'Select eligible RAMP contentions',
        valueFunction: (issue) => {
          return <Checkbox
            label={issue.description}
            name={`select-issue-${issue.id}`}
            value={issue.isSelected}
            onChange={this.onCheckIssue(issue.id)}
            unpadded
          />;
        }
      }
    ];

    const otherQuestions = [
      {
        id: 'ineligible-issue',
        text: <span>The veteran's form lists at least one <strong>ineligible</strong> contention</span>,
        isSelected: hasIneligibleIssue,
        onChange: this.props.setHasIneligibleIssue
      }
    ];

    const otherQuestionColumns = [
      {
        header: 'Select if applicable',
        valueFunction: (question) => (
          <Checkbox
            label={question.text}
            name={question.id}
            value={question.isSelected}
            onChange={question.onChange}
            unpadded
          />
        )
      }
    ];

    return <div>
      <h1>Finish processing RAMP Selection form</h1>

      <ol className="cf-bare-list">
        <li>
          <div className="cf-intake-step">
            <strong>1. Complete the following tasks outside Caseflow and mark when complete</strong>
            <span className="cf-required">Required</span>
          </div>

          <div className="cf-intake-substeps">
            <ol className="cf-bare-list">
              <li>
                <strong>1a.</strong> Upload the RAMP Selection Form to the VBMS eFolder and
                ensure the Document Type is <strong>Correspondence</strong>.</li>
              <li><strong>1b.</strong> Update the Subject Line with “RAMP Lane Selection”.</li>
            </ol>

            <Checkbox
              label="I've completed the above steps outside Caseflow."
              name="confirm-outside-caseflow-steps"
              value={outsideCaseflowStepsConfirmed}
              onChange={this.props.setOutsideCaseflowStepsConfirmed}
            />
          </div>
        </li>

        <li>
          <div className="cf-intake-step">
            <strong>2. Review and select contentions</strong>
            <span className="cf-required">Required</span>
          </div>

          <div className="cf-intake-substeps">
            <ol className="cf-bare-list">
              <li>
                <strong>2a.</strong> From the list of eligible contentions below,
                select the contentions requested for review on the Veteran’s form.
              </li>
              <li>
                <strong>2b.</strong> If the form contains any ineligible contentions,
                note via the checkbox at the bottom of the table.
              </li>
            </ol>
          </div>
        </li>
      </ol>

      {/*
          TODO: These components probably shouldn't be made with Tables, but this was
          a quick solution based on what was possible with the styleguide. We're going
          to put some more thought into the final component and add that to the styleguide
      */}
      <Table
        className="cf-table-selections"
        columns={issueColumns}
        rowObjects={_.values(issues)}
        summary={issueColumns[0].header}
        getKeyForRow={(_index, issue) => issue.id}
      />

      <Table
        className="cf-table-selections"
        columns={otherQuestionColumns}
        rowObjects={otherQuestions}
        summary={otherQuestionColumns[0].header}
        getKeyForRow={(_index, question) => question.id}
      />
    </div>;
  }
}

export default connect(
  (state) => ({
    rampRefilingStatus: getIntakeStatus(state),
    hasIneligibleIssue: state.rampRefiling.hasIneligibleIssue,
    issues: state.rampRefiling.issues,
    outsideCaseflowStepsConfirmed: state.rampRefiling.outsideCaseflowStepsConfirmed
  }),
  (dispatch) => bindActionCreators({
    setIssueSelected,
    setHasIneligibleIssue,
    setOutsideCaseflowStepsConfirmed
  }, dispatch)
)(Finish);

export class FinishButtons extends React.PureComponent {
  render = () => <CancelButton />
}
