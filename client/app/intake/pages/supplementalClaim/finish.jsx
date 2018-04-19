import React from 'react';
import { Redirect } from 'react-router-dom';
import Checkbox from '../../../components/Checkbox';
import Button from '../../../components/Button';
import TabWindow from '../../../components/TabWindow';
import CancelButton from '../../components/CancelButton';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { completeIntake, confirmFinishIntake } from '../../actions/supplementalClaim';
import { REQUEST_STATE, PAGE_PATHS, RAMP_INTAKE_STATES } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import CompleteIntakeErrorAlert from '../../components/CompleteIntakeErrorAlert';

class Finish extends React.PureComponent {
  render() {
    const {
      supplementalClaimStatus,
      requestState,
      veteranName
    } = this.props;

    const tabs = [{
      label: 'Rated issues',
      page: <RatedIssues />
    }, {
      label: 'Non-rated issues',
      page: <NonRatedIssues />
    }];

    switch (supplementalClaimStatus) {
    case RAMP_INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case RAMP_INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    return <div>
      <h1>Finish processing { veteranName }'s Supplemental Claim (VA Form 21-526b)</h1>

      { requestState === REQUEST_STATE.FAILED &&
        <CompleteIntakeErrorAlert
          completeIntakeErrorCode={completeIntakeErrorCode}
          completeIntakeErrorData={completeIntakeErrorData} />
      }

      <p>
        Select or enter the issue(s) that best match the form you are processing.
        If the Veteran listed any non-rated issues, use the "Non-rated issues" tab,
        and Caseflow will establish a non-rated EP for any non-rated issue(s).
      </p>

      <TabWindow
        name="supplemental-claim-tabwindow"
        tabs={tabs} />

    </div>;
  }
}

class RatedIssues extends React.PureComponent {
  render() {
    const ratedIssuesData = [
      {
        rba_issue_id: '123',
        decision_date: '01/28/2018',
        decision_text: 'I am a rated issue'
      },
      {
        rba_issue_id: '456',
        decision_date: '01/28/2018',
        decision_text: 'I am another rated issue'
      },
      {
        rba_issue_id: '789',
        decision_date: '02/28/2018',
        decision_text: 'I am a rated issue on a different date'
      }
    ];

    const ratedIssuesByDecisionDate = _.groupBy(ratedIssuesData, 'decision_date');

    const ratedIssuesSections = _.map(ratedIssuesByDecisionDate, (dateWithIssues) => {
      const ratedIssueCheckboxes = _.map(dateWithIssues, (issue) => {
        return (
          <Checkbox
            label={issue.decision_text}
            name='checkboxname'
            value='checkboxvalue'
            key={issue.rba_issue_id}
          />
        )
      });

      return (<div key={dateWithIssues[0].rba_issue_id}>
        <p key={dateWithIssues[0].rba_issue_id}>
          Decision date: { dateWithIssues[0].decision_date }
        </p>

        { ratedIssueCheckboxes }
      </div>
      );
    })

    return <div>
      { ratedIssuesSections }
    </div>;
  }
}

class NonRatedIssues extends React.PureComponent {
  render = () => <div>
    Non-rated Issues
  </div>;
}

class FinishNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.completeIntake(this.props.intakeId, this.props.supplementalClaim).then(
      (completeWasSuccessful) => {
        if (completeWasSuccessful) {
          this.props.history.push('/completed');
        }
      }
    );
  }

  render = () =>
    <Button
      name="submit-review"
      onClick={this.handleClick}
      loading={this.props.requestState === REQUEST_STATE.IN_PROGRESS}
      legacyStyling={false}
    >
      Establish claim
    </Button>;
}

const FinishNextButtonConnected = connect(
  ({ supplementalClaim, intake }) => ({
    requestState: supplementalClaim.requestStatus.completeIntake,
    intakeId: intake.id,
    supplementalClaim
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

export default connect(
  (state) => ({
    veteranName: state.intake.veteran.name,
    supplementalClaimStatus: getIntakeStatus(state)
  })
)(Finish);
