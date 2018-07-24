import React from 'react';
import { getIntakeStatus } from '../../selectors';
import CancelButton from '../../components/CancelButton';
import Checkbox from '../../../components/Checkbox';
import Button from '../../../components/Button';
import Table from '../../../components/Table';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, INTAKE_STATES, REQUEST_STATE } from '../../constants';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setIssueSelected, setHasIneligibleIssue, setOutsideCaseflowStepsConfirmed, completeIntake,
  processFinishError } from '../../actions/rampRefiling';
import _ from 'lodash';
import classNames from 'classnames';
import CompleteIntakeErrorAlert from '../../components/CompleteIntakeErrorAlert';

class Finish extends React.PureComponent {
  onCheckIssue = (issueId) => (checked) => this.props.setIssueSelected(issueId, checked)

  componentDidUpdate () {
    if (this.props.outsideCaseflowStepsError && !this.props.finishErrorProcessed) {
      this.outsideCaseflowStepsNode.scrollIntoView();

      // Mark finish error as processed so we don't keep scrolling back here
      this.props.processFinishError();
    }
  }

  setOutsideCaseflowStepsNode = (node) => this.outsideCaseflowStepsNode = node

  render() {
    const {
      rampRefilingStatus,
      issues,
      hasIneligibleIssue,
      outsideCaseflowStepsConfirmed,
      outsideCaseflowStepsError,
      issuesSelectedError,
      requestState,
      completeIntakeErrorCode,
      completeIntakeErrorData
    } = this.props;

    switch (rampRefilingStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case INTAKE_STATES.COMPLETED:
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
        text: <span>The Veteran's form lists at least one <strong>ineligible</strong> contention</span>,
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

      { requestState === REQUEST_STATE.FAILED &&
        <CompleteIntakeErrorAlert
          completeIntakeErrorCode={completeIntakeErrorCode}
          completeIntakeErrorData={completeIntakeErrorData} />
      }

      <ol className="cf-bare-list" ref={this.setOutsideCaseflowStepsNode}>
        <li>
          <div className="cf-intake-step">
            <strong>1. Complete the following tasks outside Caseflow and mark when complete</strong>
            <span className="cf-required">Required</span>
          </div>

          <div className="cf-intake-substeps">
            <ol className="cf-bare-list">
              <li>
                <strong>1a.</strong> Upload the RAMP Selection Form to the VBMS eFolder and
                ensure the Document Type is <strong>RAMP Opt-In Election</strong>.</li>
              <li><strong>1b.</strong> Update the Subject Line with “RAMP Selection”.</li>
            </ol>

            <Checkbox
              label="I've completed the above steps outside Caseflow."
              name="confirm-outside-caseflow-steps"
              value={outsideCaseflowStepsConfirmed}
              onChange={this.props.setOutsideCaseflowStepsConfirmed}
              errorMessage={outsideCaseflowStepsError}
            />
          </div>
        </li>

        <li>
          { outsideCaseflowStepsConfirmed && <div><div className="cf-intake-step">
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
          </div></div> }
        </li>
      </ol>

      { outsideCaseflowStepsConfirmed && <div className={classNames({ 'usa-input-error': issuesSelectedError })}>
        { issuesSelectedError &&
            <div className="usa-input-error-message">{issuesSelectedError}</div>
        }

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
      </div> }
    </div>;
  }
}

export default connect(
  (state) => ({
    rampRefilingStatus: getIntakeStatus(state),
    hasIneligibleIssue: state.rampRefiling.hasIneligibleIssue,
    issues: state.rampRefiling.issues,
    outsideCaseflowStepsConfirmed: state.rampRefiling.outsideCaseflowStepsConfirmed,
    outsideCaseflowStepsError: state.rampRefiling.outsideCaseflowStepsError,
    issuesSelectedError: state.rampRefiling.issuesSelectedError,
    finishErrorProcessed: state.rampRefiling.finishErrorProcessed,
    requestState: state.rampRefiling.requestStatus.completeIntake,
    completeIntakeErrorCode: state.rampRefiling.requestStatus.completeIntakeErrorCode,
    completeIntakeErrorData: state.rampRefiling.requestStatus.completeIntakeErrorData
  }),
  (dispatch) => bindActionCreators({
    setIssueSelected,
    setHasIneligibleIssue,
    setOutsideCaseflowStepsConfirmed,
    processFinishError
  }, dispatch)
)(Finish);

class FinishNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.completeIntake(this.props.intakeId, this.props.rampRefiling).then(
      (completeWasSuccessful) => {
        if (completeWasSuccessful) {
          this.props.history.push('/completed');
        }
      }
    );
  }

  render = () =>
    <Button
      id="finish-intake"
      onClick={this.handleClick}
      loading={this.props.requestState === REQUEST_STATE.IN_PROGRESS}
      legacyStyling={false}
    >
      Finish Intake
    </Button>;
}

const FinishNextButtonConnected = connect(
  ({ rampRefiling, intake }) => ({
    requestState: rampRefiling.requestStatus.completeIntake,
    intakeId: intake.id,
    rampRefiling
  }),
  (dispatch) => bindActionCreators({
    completeIntake
  }, dispatch)
)(FinishNextButton);

export class FinishButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelButton />
      <FinishNextButtonConnected history={this.props.history} />
    </div>
}
