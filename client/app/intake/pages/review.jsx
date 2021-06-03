import React from 'react';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { useHistory } from 'react-router';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import PropTypes from 'prop-types';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import { css } from 'glamor';

import { PAGE_PATHS, FORM_TYPES, REQUEST_STATE, VBMS_BENEFIT_TYPES } from '../constants';
import RampElectionPage, { reviewRampElectionSchema } from './rampElection/review';
import RampRefilingPage, { reviewRampRefilingSchema } from './rampRefiling/review';
import SupplementalClaimPage, { reviewSupplementalClaimSchema } from './supplementalClaim/review';
import { higherLevelReviewFormHeader, reviewHigherLevelReviewSchema } from './higherLevelReview/review';
import { appealFormHeader, reviewAppealSchema } from './appeal/review';

import Button from '../../components/Button';
import CancelButton from '../components/CancelButton';
import { submitReview as submitRampElection } from '../actions/rampElection';
import { submitReview as submitDecisionReview } from '../actions/decisionReview';
import { submitReview as submitRampRefiling } from '../actions/rampRefiling';
import { setReceiptDateError } from '../actions/intake';
import { toggleIneligibleError } from '../util';

import SwitchOnForm from '../components/SwitchOnForm';
import FormGenerator from './formGenerator';

const textAlignRightStyling = css({
  textAlign: 'right',
});

const schemaMappings = {
  appeal: reviewAppealSchema,
  higher_level_review: reviewHigherLevelReviewSchema,
  supplemental_claim: reviewSupplementalClaimSchema,
  ramp_election: reviewRampElectionSchema,
  ramp_refiling: reviewRampRefilingSchema
};

const Review = (props) => {
  const formProps = useForm(
    {
      resolver: yupResolver(schemaMappings[props.formType]),
      context: { selectedForm: props.formType, useAmaActivationDate: props.featureToggles.useAmaActivationDate },
      mode: 'onSubmit',
      reValidateMode: 'onSubmit'
    }
  );

  const { push } = useHistory();
  const selectedForm = _.find(FORM_TYPES, { key: props.formType });
  const intakeData = selectedForm ? props.intakeForms[selectedForm.key] : null;

  const submitReview = () => {
    if (selectedForm.category === 'decisionReview') {
      return props.submitDecisionReview(props.intakeId, intakeData, selectedForm.formName);
    }

    if (selectedForm.key === 'ramp_election') {
      return props.submitRampElection(props.intakeId, intakeData);
    }

    if (selectedForm.key === 'ramp_refiling') {
      return props.submitRampRefiling(props.intakeId, intakeData);
    }
  };

  const handleClick = () => {
    if (intakeData?.claimant === 'claimant_not_listed') {
      return push('/add_claimant');
    }
    submitReview().then(
      () => selectedForm.category === 'decisionReview' ?
        push('/add_issues') :
        push('/finish')
      , (error) => {
        // This is expected behavior on bad data, so prevent
        // sentry from alerting an unhandled error
        return error;
      });
  };

  return (
    <form
      onSubmit={formProps.handleSubmit(handleClick)}
    >
      <SwitchOnForm
        formComponentMapping={{
          ramp_election: <RampElectionPage {...formProps} />,
          ramp_refiling: <RampRefilingPage {...formProps} />,
          supplemental_claim: <SupplementalClaimPage featureToggles={props.featureToggles} {...formProps} />,
          higher_level_review: <FormGenerator
            formName={selectedForm?.formName}
            formHeader={higherLevelReviewFormHeader}
            schema={schemaMappings.higher_level_review}
            featureToggles={props.featureToggles}
            {...formProps}
          />,
          appeal: <FormGenerator
            formName={selectedForm?.formName}
            formHeader={appealFormHeader}
            schema={schemaMappings.appeal}
            featureToggles={props.featureToggles}
            {...formProps}
          />
        }}
        componentForNoFormSelected={<Redirect to={PAGE_PATHS.BEGIN} />}
      />
      <nav role="navigation" className={`cf-app-segment ${textAlignRightStyling}`}>
        <ReviewButtons />
      </nav>
    </form>

  );
};

export default connect(
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
    submitDecisionReview,
    setReceiptDateError
  }, dispatch)
)(Review);

const ReviewNextButton = (props) => {
  const {
    intakeForms,
    formType
  } = props;

  // selected form might be null or empty if the review has been canceled
  // in that case, just use null as data types since page will be redirected
  const selectedFormState = _.find(FORM_TYPES, { key: formType });
  const intakeDataState = selectedFormState ? intakeForms[selectedFormState.key] : null;

  const rampRefilingIneligibleOption = () => {
    if (formType === 'ramp_refiling') {
      return toggleIneligibleError(intakeDataState.hasInvalidOption, intakeDataState.optionSelected);
    }

    return false;
  };

  const invalidVet = intakeDataState &&
    !intakeDataState.veteranValid &&
    VBMS_BENEFIT_TYPES.includes(intakeDataState.benefitType);
  const needsClaimant =
    intakeDataState?.veteranIsNotClaimant &&
    intakeDataState.relationships.length === 0 &&
    !(intakeDataState?.claimant || intakeDataState.claimantNotes);
  const disableSubmit = rampRefilingIneligibleOption() || needsClaimant || invalidVet;

  return <Button
    id="button-submit-review"
    type="submit"
    name="submit-review"
    loading={intakeDataState ? intakeDataState.requestStatus.submitReview === REQUEST_STATE.IN_PROGRESS : true}
    disabled={disableSubmit}
  >
    Continue to next step
  </Button>;
};

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
  })
)(ReviewNextButton);

const ReviewButtons = (props) => {
  return (
    <div>
      <CancelButton />
      <ReviewNextButtonConnected history={props.history} {...props} />
    </div>
  );
};

ReviewNextButton.propTypes = {
  history: PropTypes.object,
  featureToggles: PropTypes.object,
  formType: PropTypes.string,
  intakeForms: PropTypes.object,
  intakeId: PropTypes.number,
};

Review.propTypes = {
  featureToggles: PropTypes.object,
  submitRampElection: PropTypes.func,
  submitDecisionReview: PropTypes.func,
  submitRampRefiling: PropTypes.func,
  setReceiptDateError: PropTypes.func,
  intakeForms: PropTypes.object,
  formType: PropTypes.string,
  intakeId: PropTypes.number,
};

ReviewButtons.propTypes = {
  history: PropTypes.object
};
