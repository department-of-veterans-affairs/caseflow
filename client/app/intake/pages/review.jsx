import React from 'react';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import { PAGE_PATHS, FORM_TYPES, REQUEST_STATE } from '../constants';
import RampElectionPage from './rampElection/review';
import RampRefilingPage from './rampRefiling/review';
import SupplementalClaimPage from './supplementalClaim/review';
import HigherLevelReviewPage from './higherLevelReview/review';
import AppealReviewPage from './appeal/review';

import Button from '../../components/Button';
import CancelButton from '../components/CancelButton';
import { submitReview as submitRampElection } from '../actions/rampElection';
import { submitReview as submitDecisionReview } from '../actions/decisionReview';
import { submitReview as submitRampRefiling } from '../actions/rampRefiling';
import { toggleIneligibleError } from '../util';

import SwitchOnForm from '../components/SwitchOnForm';

class Review extends React.PureComponent {
  render = () =>
    <SwitchOnForm
      formComponentMapping={{
        ramp_election: <RampElectionPage />,
        ramp_refiling: <RampRefilingPage />,
        supplemental_claim: <SupplementalClaimPage featureToggles={this.props.featureToggles} />,
        higher_level_review: <HigherLevelReviewPage featureToggles={this.props.featureToggles} />,
        appeal: <AppealReviewPage featureToggles={this.props.featureToggles} />
      }}
      componentForNoFormSelected={<Redirect to={PAGE_PATHS.BEGIN} />}
    />;
}

export default connect(
  ({ intake }) => ({ formType: intake.formType })
)(Review);

class ReviewNextButton extends React.PureComponent {
  submitReview = (selectedForm, intakeData) => {
    if (selectedForm.category === 'decisionReview') {
      return this.props.submitDecisionReview(this.props.intakeId, intakeData, selectedForm.formName);
    }

    if (selectedForm.key === 'ramp_election') {
      return this.props.submitRampElection(this.props.intakeId, intakeData);
    }

    if (selectedForm.key === 'ramp_refiling') {
      return this.props.submitRampRefiling(this.props.intakeId, intakeData);
    }
  }

  handleClick = (selectedForm, intakeData) => {
    this.submitReview(selectedForm, intakeData).then(
      () => selectedForm.category === 'decisionReview' ?
        this.props.history.push('/add_issues') :
        this.props.history.push('/finish')
      , (error) => {
        // This is expected behavior on bad data, so prevent
        // sentry from alerting an unhandled error
        return error;
      });
  }

  render = () => {
    const {
      intakeForms,
      formType
    } = this.props;

    // selected form might be null or empty if the review has been canceled
    // in that case, just use null as data types since page will be redirected
    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const intakeData = selectedForm ? intakeForms[selectedForm.key] : null;
    const needsRelationships = intakeData && intakeData.veteranIsNotClaimant && intakeData.relationships.length === 0;

    return <Button
      name="submit-review"
      onClick={() => {
        this.handleClick(selectedForm, intakeData);
      }}
      loading={intakeData ? intakeData.requestStatus.submitReview === REQUEST_STATE.IN_PROGRESS : true}
      disabled={formType === 'ramp_refiling' ?
        toggleIneligibleError(intakeData.hasInvalidOption, intakeData.optionSelected) : needsRelationships}
    >
      Continue to next step
    </Button>;
  }
}

const ReviewNextButtonConnected = connect(
  (state) => ({
    intakeForms: {
      higher_level_review: state.higherLevelReview,
      supplemental_claim: state.supplementalClaim,
      appeal: state.appeal,
      ramp_refiling: state.rampRefiling,
      ramp_election: state.rampElection
    },
    intakeId: state.intake.id,
    formType: state.intake.formType,
    featureToggles: state.featureToggles
  }),
  (dispatch) => bindActionCreators({
    submitRampElection,
    submitRampRefiling,
    submitDecisionReview
  }, dispatch)
)(ReviewNextButton);

export class ReviewButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelButton />
      <ReviewNextButtonConnected history={this.props.history} />
    </div>
}
