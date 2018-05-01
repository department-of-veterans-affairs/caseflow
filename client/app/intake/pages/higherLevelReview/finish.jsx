import React from 'react';
import { connect } from 'react-redux';
import Button from '../../../components/Button';
import TabWindow from '../../../components/TabWindow';
import CancelButton from '../../components/CancelButton';
import NonRatedIssues from './nonRatedIssues';
import RatedIssues from './ratedIssues';
import { Redirect } from 'react-router-dom';
import { REQUEST_STATE, PAGE_PATHS, INTAKE_STATES } from '../../constants';
import { getIntakeStatus } from '../../selectors';

class Finish extends React.PureComponent {
  render() {
    const {
      higherLevelReviewStatus,
      veteranName
    } = this.props;

    const tabs = [{
      label: 'Rated issues',
      page: <RatedIssues />
    }, {
      label: 'Non-rated issues',
      page: <NonRatedIssues />
    }];

    switch (higherLevelReviewStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    return <div>
      <h1>Finish processing { veteranName }'s Higher-Level Review (VA Form 20-0988)</h1>

      <p>
        Select or enter the issue(s) that best match the form you are processing.
        If the Veteran listed any non-rated issues, use the "Non-rated issues" tab,
        and Caseflow will establish a non-rated EP for any non-rated issue(s).
      </p>

      <TabWindow
        name="higher-level-review-tabwindow"
        tabs={tabs} />

    </div>;
  }
}

class FinishNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.completeIntake(this.props.intakeId, this.props.higherLevelReview).then(
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
  ({ higherLevelReview, intake }) => ({
    requestState: higherLevelReview.requestStatus.completeIntake,
    intakeId: intake.id,
    higherLevelReview
  })
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
    higherLevelReviewStatus: getIntakeStatus(state)
  })
)(Finish);
