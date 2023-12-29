import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import Button from '../../../components/Button';
import CancelButton from '../../components/CancelButton';
import IssueCounter from '../../components/IssueCounter';
import { completeIntake } from '../../actions/decisionReview';
import { REQUEST_STATE, FORM_TYPES } from '../../constants';
import { issueCountSelector } from '../../selectors';
import { some } from 'lodash';
import PropTypes from 'prop-types';

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

  buttonText = () => {
    const { benefitType, addedIssues, processedInCaseflow } = this.props.higherLevelReview;

    if (benefitType === 'vha' && some(addedIssues, (obj) => !obj.decisionDate)) {
      return `Save ${FORM_TYPES.HIGHER_LEVEL_REVIEW.shortName}`;
    }

    if (processedInCaseflow) {
      return `Establish ${FORM_TYPES.HIGHER_LEVEL_REVIEW.shortName}`;
    }

    return 'Establish EP';
  }

  render = () =>
    <Button
      name="finish-intake"
      onClick={this.handleClick}
      loading={this.props.requestState === REQUEST_STATE.IN_PROGRESS}
      disabled={!this.props.issueCount && !this.props.addedIssues}
    >
      {this.buttonText()}
    </Button>;
}

FinishNextButton.propTypes = {
  issueCount: PropTypes.number,
  requestState: PropTypes.string,
  addedIssues: PropTypes.shape([PropTypes.object]),
  higherLevelReview: PropTypes.object,
  completeIntake: PropTypes.func,
  history: PropTypes.object,
  intakeId: PropTypes.number,
};

const FinishNextButtonConnected = connect(
  ({ higherLevelReview, intake }) => ({
    requestState: higherLevelReview.requestStatus.completeIntake,
    intakeId: intake.id,
    higherLevelReview,
    issueCount: issueCountSelector(higherLevelReview)
  }),
  (dispatch) => bindActionCreators({
    completeIntake
  }, dispatch)
)(FinishNextButton);

const mapStateToProps = (state) => {
  return {
    issueCount: issueCountSelector(state.higherLevelReview)
  };
};

const IssueCounterConnected = connect(mapStateToProps)(IssueCounter);

export class FinishButtons extends React.PureComponent {
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

