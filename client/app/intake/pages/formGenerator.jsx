/* eslint-disable max-len */
/* eslint max-lines: off */
import React, { Fragment } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { Redirect } from 'react-router-dom';
import { reject, map } from 'lodash';
import RadioField from '../../components/RadioField';
import ReceiptDateInput from './receiptDateInput';
import { setDocketType, setOriginalHearingRequestType, setHomelessnessType
} from '../actions/appeal';
import { setReceiptDate, setOptionSelected } from '../actions/intake';
import { setAppealDocket, confirmIneligibleForm } from '../actions/rampRefiling';
import { toggleIneligibleError, convertStringToBoolean } from '../util';
import LegacyOptInApproved from '../components/LegacyOptInApproved';
import Homelessness from '../components/Homelessness';
import {
  setVeteranIsNotClaimant, setClaimant, setPayeeCode, setLegacyOptInApproved, setBenefitType, setFiledByVaGov
} from '../actions/decisionReview';
import { setInformalConference, setSameOffice } from '../actions/higherLevelReview';
import { bindActionCreators } from 'redux';
import { getIntakeStatus } from '../selectors';
import SelectClaimant from '../components/SelectClaimant';
import BenefitType from '../components/BenefitType';
import { BOOLEAN_RADIO_OPTIONS, FORM_TYPES, INTAKE_STATES, PAGE_PATHS, REQUEST_STATE, REVIEW_OPTIONS, VBMS_BENEFIT_TYPES } from '../constants';
import ErrorAlert from '../components/ErrorAlert';
import COPY from '../../../COPY';
import Alert from '../../components/Alert';
import Button from '../../components/Button';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { sprintf } from 'sprintf-js';
import Link from 'app/components/Link';
import { renderToString } from 'react-dom/server';
const docketTypeRadioOptions = [
  { value: 'direct_review', displayText: 'Direct Review' },
  { value: 'evidence_submission', displayText: 'Evidence Submission' },
  { value: 'hearing', displayText: 'Hearing' },
];
const hearingTypeOptions = [
  { label: 'Central Office Hearing', value: 'central' },
  { label: 'Videoconference Hearing', value: 'video' },
  { label: 'Virtual Telehearing', value: 'virtual' },
];
const rampElectionReviewOptions = reject(REVIEW_OPTIONS, REVIEW_OPTIONS.APPEAL);
const rampRefilingRadioOptions = map(REVIEW_OPTIONS, (option) => ({
  value: option.key,
  displayText: option.name,
}));
const rampElectionRadioOptions = map(rampElectionReviewOptions, (option) => ({
  value: option.key,
  displayText: option.name,
}));
const formFieldMapping = (props) => {
  const isAppeal = props.formName === FORM_TYPES.APPEAL.formName;
  const renderBooleanValue = (propKey) => {
    // eslint-disable-next-line no-undefined
    return props[propKey] === null || props[propKey] === undefined ? null : props[propKey].toString();
  };
  const renderVaGovValue = () => {
    // eslint-disable-next-line no-undefined
    if (isAppeal && (props.filedByVaGov === null || props.filedByVaGov === undefined)) {
      return 'false';
    }

    return renderBooleanValue('filedByVaGov');
  };
  const hearingTypeDropdown = (
    <SearchableDropdown
      label="Please Select Hearing Type"
      strongLabel
      name="original-hearing-request-type"
      onChange={({ value }) => props.setOriginalHearingRequestType(value)}
      options={hearingTypeOptions}
      optional
    />
  );
  const updateDocketType = (event) => {
    // reset hearing type if switching to a non-hearing docket type
    if (props.docketType === 'hearing' && props.featureToggles.updatedAppealForm) {
      props.setOriginalHearingRequestType(null);
    }
    props.setDocketType(event);
  };
  const homelessnessFieldValue = () => {
    return (props.homelessnessUserInteraction || props.isReviewed) ?
      props.homelessness :
      null;
  };
  const homelessnessRadioField = (
    <Homelessness
      value={homelessnessFieldValue()}
      onChange={props.setHomelessnessType}
      errorMessage={props.homelessnessError || props.errors?.['homelessness']?.message}
      register={props.register}
    />
  );

  return ({
    'receipt-date': <ReceiptDateInput {...props} />,
    'docket-type': (
      <div className="cf-docket-type" style={{ marginTop: '10px' }}>
        <RadioField
          name="docket-type"
          label="Which review option did the Veteran request?"
          strongLabel
          vertical
          options={docketTypeRadioOptions}
          onChange={(value) => {
            updateDocketType(value);
          }}
          errorMessage={
            props.docketTypeError || props.errors?.['docket-type']?.message
          }
          value={props.docketType}
          inputRef={props.register}
        />
      </div>
    ),
    'original-hearing-request-type':
     props.docketType === 'hearing' && props.featureToggles.updatedAppealForm ? hearingTypeDropdown : <></>,
    'legacy-opt-in': (
      <LegacyOptInApproved
        value={props.legacyOptInApproved}
        onChange={props.setLegacyOptInApproved}
        errorMessage={
          props.legacyOptInApprovedError ||
          props.errors?.['legacy-opt-in']?.message
        }
        register={props.register}
      />
    ),
    'different-claimant-option': (
      <SelectClaimantConnected
        register={props.register}
        errors={props.errors}
        formName={props.formName}
      />
    ),
    'benefit-type-options': (
      <BenefitType
        value={props.benefitType}
        onChange={props.setBenefitType}
        errorMessage={
          props.benefitTypeError ||
          props.errors?.['benefit-type-options']?.message
        }
        register={props.register}
        formName={props.formName}
        featureToggles={props.featureToggles}
        userCanSelectVha={props.userIsVhaEmployee}
      />
    ),
    'informal-conference': (
      <RadioField
        name="informal-conference"
        label="Was an informal conference requested?"
        strongLabel
        vertical
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={(value) => {
          props.setInformalConference(convertStringToBoolean(value));
        }}
        errorMessage={
          props.informalConferenceError ||
          props.errors?.['informal-conference']?.message
        }
        value={renderBooleanValue('informalConference')}
        inputRef={props.register}
      />
    ),
    'same-office': (
      <RadioField
        name="same-office"
        label="Was an interview by the same office requested?"
        strongLabel
        vertical
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={(value) => {
          props.setSameOffice(convertStringToBoolean(value));
        }}
        errorMessage={
          props.sameOfficeError || props.errors?.['same-office']?.message
        }
        value={renderBooleanValue('sameOffice')}
        inputRef={props.register}
      />
    ),
    'filed-by-va-gov': (
      <RadioField
        name="filed-by-va-gov"
        label={
          <span>
            <b>Was this form submitted through VA.gov? </b>
            (Indicated by a stamp at the top right corner of the form)
          </span>
        }
        vertical
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={(value) => {
          props.setFiledByVaGov(convertStringToBoolean(value));
        }}
        errorMessage={
          props.filedByVaGovError || props.errors?.['filed-by-va-gov']?.message
        }
        value={renderVaGovValue()}
        inputRef={props.register}
      />
    ),
    'homelessness-type': props.featureToggles.updatedAppealForm ? homelessnessRadioField : <></>,
    'opt-in-election': (
      <Fragment>
        <RadioField
          name="opt-in-election"
          label="Which review lane did the Veteran select?"
          strongLabel
          options={
            props.formName === FORM_TYPES.RAMP_REFILING.formName ?
              rampRefilingRadioOptions :
              rampElectionRadioOptions
          }
          onChange={props.setOptionSelected}
          errorMessage={
            props.optionSelectedError ||
            props.errors?.['opt-in-election']?.message
          }
          value={props.optionSelected}
          inputRef={props.register}
        />
        {props.optionSelected === REVIEW_OPTIONS.APPEAL.key && (
          <RadioField
            name="appeal-docket"
            label="Which type of appeal did the Veteran request?"
            strongLabel
            options={docketTypeRadioOptions}
            onChange={props.setAppealDocket}
            errorMessage={
              props.appealDocketError ||
              props.errors?.['appeal-docket']?.message
            }
            value={props.appealDocket}
            inputRef={props.register}
          />
        )}
      </Fragment>
    ),
  });
};
const FormGenerator = (props) => {
  switch (props.intakeStatus) {
  case INTAKE_STATES.NONE:
    return <Redirect to={PAGE_PATHS.BEGIN} />;
  case INTAKE_STATES.COMPLETED:
    return <Redirect to={PAGE_PATHS.COMPLETED} />;
  default:
  }

  const beginNextIntake = () => {
    props.confirmIneligibleForm(props.intakeId);
  };
  const showInvalidVeteranError = !props.veteranValid && VBMS_BENEFIT_TYPES.includes(props.benefitType);

  const buildVHAInfoBannerMessage = () => {
    const emailSubject = 'Potential%20VHA%20Higher-Level%20Review%20or%20Supplemental%20Claim';
    const mailToLink = <Link href={`mailto:${COPY.VHA_BENEFIT_EMAIL_ADDRESS}?subject=${emailSubject}`}>
      <span>{COPY.VHA_BENEFIT_EMAIL_ADDRESS}</span>
    </Link>;

    return sprintf(COPY.INTAKE_VHA_CLAIM_REVIEW_REQUIREMENT, renderToString(mailToLink));
  };

  const isHlrOrScForm = [FORM_TYPES.HIGHER_LEVEL_REVIEW.formName, FORM_TYPES.SUPPLEMENTAL_CLAIM.formName].includes(props.formName);

  return (
    <div>
      <h1>{props.formHeader(props.veteranName)}</h1>
      {toggleIneligibleError(props.hasInvalidOption, props.optionSelected) && (
        <Alert title="Ineligible for Higher-Level Review" type="error">
          {COPY.INELIGIBLE_HIGHER_LEVEL_REVIEW_ALERT} <br />
          <Button
            name="begin-next-intake"
            onClick={beginNextIntake}
            loading={props.requestState === REQUEST_STATE.IN_PROGRESS}
            type="button"
          >
            Begin next intake
          </Button>
        </Alert>
      )}
      {props.reviewIntakeError && <ErrorAlert {...props.reviewIntakeError} />}
      {showInvalidVeteranError && (
        <ErrorAlert
          errorCode="veteran_not_valid"
          errorData={props.veteranInvalidFields}
        />
      )}
      {!props.userIsVhaEmployee && isHlrOrScForm && props.featureToggles.vhaClaimReviewEstablishment && (
        <div style={{ marginBottom: '3rem' }}>
          <Alert title={COPY.INTAKE_VHA_CLAIM_REVIEW_REQUIREMENT_TITLE} type="info">
            <span dangerouslySetInnerHTML={{ __html: buildVHAInfoBannerMessage() }} />
          </Alert>
        </div>
      )}
      {Object.keys(props.schema.fields).map((field) => formFieldMapping(props)[field])}
    </div>
  );
};
const SelectClaimantConnected = connect(
  (state, props) => {
    const { featureToggles } = state;

    return {
      isVeteranDeceased: state.intake.veteran.isDeceased,
      veteranIsNotClaimant: state[props.formName].veteranIsNotClaimant,
      veteranIsNotClaimantError: state[props.formName].veteranIsNotClaimantError,
      claimant: state[props.formName].claimant,
      claimantError: state[props.formName].claimantError,
      payeeCode: state[props.formName].payeeCode,
      payeeCodeError: state[props.formName].payeeCodeError,
      relationships: state[props.formName].relationships,
      benefitType: state[props.formName].benefitType,
      formType: state.intake.formType,
      featureToggles,
    };
  },
  (dispatch) =>
    bindActionCreators({
      setVeteranIsNotClaimant,
      setClaimant,
      setPayeeCode,
    }, dispatch)
)(SelectClaimant);

FormGenerator.propTypes = {
  schema: PropTypes.object.isRequired,
  formHeader: PropTypes.func.isRequired,
  formName: PropTypes.string.isRequired,
  veteranName: PropTypes.string,
  receiptDate: PropTypes.string,
  receiptDateError: PropTypes.string,
  docketType: PropTypes.string,
  docketTypeError: PropTypes.string,
  legacyOptInApproved: PropTypes.bool,
  legacyOptInApprovedError: PropTypes.string,
  reviewIntakeError: PropTypes.object,
  setDocketType: PropTypes.func,
  setReceiptDate: PropTypes.func,
  setOriginalHearingRequestType: PropTypes.func,
  originalHearingRequestType: PropTypes.string,
  setLegacyOptInApproved: PropTypes.func,
  appealStatus: PropTypes.string,
  intakeStatus: PropTypes.string,
  veteranValid: PropTypes.bool,
  veteranInvalidFields: PropTypes.object,
  benefitType: PropTypes.string,
  confirmIneligibleForm: PropTypes.string,
  hasInvalidOption: PropTypes.string,
  optionSelected: PropTypes.string,
  requestState: PropTypes.string,
  register: PropTypes.func,
  errors: PropTypes.array,
  intakeId: PropTypes.string,
  homelessness: PropTypes.string,
  setHomelessnessType: PropTypes.func,
  homelessnessError: PropTypes.string,
  isReviewed: PropTypes.bool,
  userIsVhaEmployee: PropTypes.bool,
  featureToggles: PropTypes.object,
};
export default connect(
  (state, props) => ({
    veteranName: state.intake.veteran.name,
    intakeId: state.intake.id,
    intakeStatus: getIntakeStatus(state),
    receiptDate: state[props.formName].receiptDate,
    receiptDateError: state[props.formName].receiptDateError,
    filedByVaGov: state[props.formName].filedByVaGov,
    filedByVaGovError: state[props.formName].filedByVaGovError,
    docketType: state[props.formName].docketType,
    docketTypeError: state[props.formName].docketTypeError,
    originalHearingRequestType: state[props.formName].originalHearingRequestType,
    legacyOptInApproved: state[props.formName].legacyOptInApproved,
    legacyOptInApprovedError: state[props.formName].legacyOptInApprovedError,
    benefitType: state[props.formName].benefitType,
    benefitTypeError: state[props.formName].benefitTypeError,
    informalConference: state[props.formName].informalConference,
    informalConferenceError: state[props.formName].informalConferenceError,
    optionSelected: state[props.formName].optionSelected,
    optionSelectedError: state[props.formName].optionSelectedError,
    sameOffice: state[props.formName].sameOffice,
    sameOfficeError: state[props.formName].sameOfficeError,
    appealDocket: state[props.formName].appealDocket,
    appealDocketError: state[props.formName].appealDocketError,
    reviewIntakeError: state[props.formName].requestStatus.reviewIntakeError,
    veteranValid: state[props.formName].veteranValid,
    veteranInvalidFields: state[props.formName].veteranInvalidFields,
    hasInvalidOption: state[props.formName].hasInvalidOption,
    confirmIneligibleForm: state[props.formName].confirmIneligibleForm,
    homelessness: state[props.formName].homelessness,
    homelessnessError: state[props.formName].homelessnessError,
    homelessnessUserInteraction: state[props.formName].homelessnessUserInteraction,
    isReviewed: state[props.formName].isReviewed,
    userIsVhaEmployee: state.userInformation.userIsVhaEmployee,
    featureToggles: state.featureToggles,
  }),
  (dispatch) => bindActionCreators({
    setDocketType,
    setReceiptDate,
    setLegacyOptInApproved,
    setInformalConference,
    setOriginalHearingRequestType,
    setSameOffice,
    setBenefitType,
    setAppealDocket,
    confirmIneligibleForm,
    setOptionSelected,
    setFiledByVaGov,
    setHomelessnessType
  }, dispatch)
)(FormGenerator);
