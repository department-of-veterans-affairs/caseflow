import React from 'react';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { useHistory } from 'react-router';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import PropTypes from 'prop-types';
import * as yup from 'yup';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import { format } from 'date-fns';
import { css } from 'glamor';

import { PAGE_PATHS, FORM_TYPES, REQUEST_STATE, VBMS_BENEFIT_TYPES, REVIEW_OPTIONS } from '../constants';
import RampElectionPage, { reviewRampElectionSchema } from './rampElection/review';
import RampRefilingPage, { reviewRampRefilingSchema } from './rampRefiling/review';
import SupplementalClaimPage, { reviewSupplementalClaimSchema } from './supplementalClaim/review';
import HigherLevelReviewPage, {reviewHigherLevelReviewSchema} from './higherLevelReview/review';
import AppealReviewPage, {reviewAppealSchema} from './appeal/review';

import Button from '../../components/Button';
import CancelButton from '../components/CancelButton';
import { submitReview as submitRampElection } from '../actions/rampElection';
import { submitReview as submitDecisionReview } from '../actions/decisionReview';
import { submitReview as submitRampRefiling } from '../actions/rampRefiling';
import { setReceiptDateError } from '../actions/intake';
import { toggleIneligibleError } from '../util';
import DATES from '../../../constants/DATES';

import SwitchOnForm from '../components/SwitchOnForm';

const textAlignRightStyling = css({
  textAlign: 'right',
});

const schemaMappings = {
  appeal: reviewAppealSchema,
  higher_level_review: reviewHigherLevelReviewSchema,
  supplemental_claim: reviewSupplementalClaimSchema,
  ramp_election: reviewRampElectionSchema,
  ramp_refiling: reviewRampRefilingSchema
}

const schema = yup.object().shape({
  'receipt-date': yup.mixed().
    when(['$selectedForm', '$useAmaActivationDate'], {
      is: (selectedForm, useAmaActivationDate) => console.log(selectedForm) || selectedForm === REVIEW_OPTIONS.APPEAL.key && useAmaActivationDate,
      then: yup.date().typeError('Receipt Date is required.').
        min(
          new Date(DATES.AMA_ACTIVATION),
        `Receipt Date cannot be prior to ${format(new Date(DATES.AMA_ACTIVATION), 'MM/dd/yyyy')}`
        )
    }).
    when(['$selectedForm', '$useAmaActivationDate'], {
      is: (selectedForm, useAmaActivationDate) => selectedForm === REVIEW_OPTIONS.APPEAL.key && !useAmaActivationDate,
      then: yup.date().typeError('Receipt Date is required.').
        min(
          new Date(DATES.AMA_ACTIVATION_TEST),
        `Receipt Date cannot be prior to ${format(new Date(DATES.AMA_ACTIVATION_TEST), 'MM/dd/yyyy')}`
        )
    }),
    'docket-type': yup.string().required(),
    'legacy-opt-in': yup.string().required(),
    'different-claimant-option': yup.string().required(),
    'claimant-options': yup.string().notRequired().when('different-claimant-option', {
      is: "true",
      then: yup.string().required()
    })
});

const Review = ({
  featureToggles, 
  submitDecisionReview, 
  submitRampElection, 
  submitRampRefiling, 
  intakeForms, 
  formType, 
  intakeId
}) => {
  console.log(formType)
  const { register, errors, handleSubmit } = useForm(
    {
      resolver: yupResolver(schemaMappings[formType]),
      context: { selectedForm: formType, useAmaActivationDate: featureToggles.useAmaActivationDate}
    }
  );

  const { push } = useHistory();
  const selectedForm = _.find(FORM_TYPES, { key: formType });
  const intakeData = selectedForm ? intakeForms[selectedForm.key] : null;

  const submitReview = (selectedForm, intakeData) => {
    if (selectedForm.category === 'decisionReview') {
      return submitDecisionReview(intakeId, intakeData, selectedForm.formName);
    }

    if (selectedForm.key === 'ramp_election') {
      return submitRampElection(intakeId, intakeData);
    }

    if (selectedForm.key === 'ramp_refiling') {
      return submitRampRefiling(intakeId, intakeData);
    }
  }

  const handleClick = () => {
    if (intakeData?.claimant === 'claimant_not_listed') {
      return push('/add_claimant');
    }
    submitReview(selectedForm, intakeData).then(
      () => selectedForm.category === 'decisionReview' ?
        push('/add_issues') :
        push('/finish')
      , (error) => {
        // This is expected behavior on bad data, so prevent
        // sentry from alerting an unhandled error
        return error;
      });
  }

  return(
    <form
      onSubmit={handleSubmit(handleClick)}
    >
      <SwitchOnForm
        formComponentMapping={{
          ramp_election: <RampElectionPage errors={errors} register={register} />,
          ramp_refiling: <RampRefilingPage errors={errors} register={register} />,
          supplemental_claim: <SupplementalClaimPage featureToggles={featureToggles} errors={errors} register={register} />,
          higher_level_review: <HigherLevelReviewPage featureToggles={featureToggles} errors={errors} register={register} />,
          appeal: <AppealReviewPage featureToggles={featureToggles} errors={errors} register={register} />
        }}
        componentForNoFormSelected={<Redirect to={PAGE_PATHS.BEGIN} />}
      />
      <nav role="navigation" className={`cf-app-segment ${textAlignRightStyling}`}>
        <ReviewButtons />
      </nav>
    </form>
    
  )
}

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
    submitDecisionReview
  }, dispatch)
)(Review);

class ReviewNextButton extends React.PureComponent {
  render = () => {
    const {
      intakeForms,
      formType,
      handleSubmit
    } = this.props;

    // selected form might be null or empty if the review has been canceled
    // in that case, just use null as data types since page will be redirected
    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const intakeData = selectedForm ? intakeForms[selectedForm.key] : null;

    const rampRefilingIneligibleOption = () => {
      if (formType === 'ramp_refiling') {
        return toggleIneligibleError(intakeData.hasInvalidOption, intakeData.optionSelected);
      }

      return false;
    };

    const invalidVet = intakeData && !intakeData.veteranValid && VBMS_BENEFIT_TYPES.includes(intakeData.benefitType);
    const needsClaimant =
      intakeData?.veteranIsNotClaimant &&
      intakeData.relationships.length === 0 &&
      !(intakeData?.claimant || intakeData.claimantNotes);
    const disableSubmit = rampRefilingIneligibleOption() || needsClaimant || invalidVet;

    return <Button
      type="submit"
      name="submit-review"
      loading={intakeData ? intakeData.requestStatus.submitReview === REQUEST_STATE.IN_PROGRESS : true}
      disabled={disableSubmit}
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
    submitDecisionReview,
    setReceiptDateError
  }, dispatch)
)(ReviewNextButton);

export class ReviewButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelButton />
      <ReviewNextButtonConnected history={this.props.history} {...this.props} />
    </div>
}

ReviewNextButton.propTypes = {
  history: PropTypes.object,
  featureToggles: PropTypes.object,
  formType: PropTypes.string,
  intakeForms: PropTypes.object,
  intakeId: PropTypes.number,
  submitRampElection: PropTypes.func,
  submitDecisionReview: PropTypes.func,
  submitRampRefiling: PropTypes.func,
  setReceiptDateError: PropTypes.func
};

Review.propTypes = {
  featureToggles: PropTypes.object
};

ReviewButtons.propTypes = {
  history: PropTypes.object
};

export { schema as TestableSchema };
