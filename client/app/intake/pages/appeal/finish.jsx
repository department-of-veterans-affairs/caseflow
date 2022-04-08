import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import Button from '../../../components/Button';
import CancelButton from '../../components/CancelButton';
import IssueCounter from '../../components/IssueCounter';
import { completeIntake } from '../../actions/decisionReview';
import { REQUEST_STATE, VBMS_BENEFIT_TYPES } from '../../constants';
import { issueCountSelector } from '../../selectors';
import _ from 'lodash';

const mapStateToProps = (state) => {
  return {
    issueCount: issueCountSelector(state.appeal)
  };
};

const IssueCounterConnected = connect(mapStateToProps)(IssueCounter);

const invalidVeteran = (appeal) => !appeal.veteranValid && (_.some(
  appeal.addedIssues, (issue) => VBMS_BENEFIT_TYPES.includes(issue.benefitType) || issue.ratingIssueReferenceId)
);

class FinishNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.completeIntake(this.props.intakeId, this.props.appeal).then(
      (completeWasSuccessful) => {
        if (completeWasSuccessful) {
          this.props.history.push('/completed');
        }
      }
    );
  };

  render() {
    const disableSubmit = (!this.props.issueCount && !this.props.addedIssues) || invalidVeteran(this.props.appeal);
    const hasPreDocketIssues = _.some(this.props.appeal.addedIssues, (issue) => issue.isPreDocketNeeded === 'true');
    const buttonAction = hasPreDocketIssues ? 'Submit' : 'Establish';

    return <Button
      name="finish-intake"
      onClick={this.handleClick}
      loading={this.props.requestState === REQUEST_STATE.IN_PROGRESS}
      disabled={disableSubmit}
    >
      {`${buttonAction} appeal`}
    </Button>;
  }
}

FinishNextButton.propTypes = {
  intakeId: PropTypes.number,
  appeal: PropTypes.object,
  completeIntake: PropTypes.func,
  issueCount: PropTypes.number,
  requestState: PropTypes.string,
  history: PropTypes.object,
  addedIssues: PropTypes.array
};

const FinishNextButtonConnected = connect(
  ({ appeal, intake }) => ({
    requestState: appeal.requestStatus.completeIntake,
    intakeId: intake.id,
    appeal,
    issueCount: issueCountSelector(appeal)
  }),
  (dispatch) => bindActionCreators({
    completeIntake
  }, dispatch)
)(FinishNextButton);

class FinishButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelButton />
      <FinishNextButtonConnected history={this.props.history} />
      <IssueCounterConnected />
    </div>
}

FinishButtons.propTypes = {
  history: PropTypes.object
};

export { FinishButtons };
