/* eslint-disable max-lines */
import React, { useState, useEffect, useMemo } from 'react';
import { bindActionCreators } from 'redux';
import { connect, useSelector } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';
import PropTypes from 'prop-types';
import { format, isDate, max, parseISO } from 'date-fns';
import COPY from '../../../COPY';
import CAVC_JUDGE_FULL_NAMES from '../../../constants/CAVC_JUDGE_FULL_NAMES';
import CAVC_REMAND_SUBTYPES from '../../../constants/CAVC_REMAND_SUBTYPES';
import CAVC_REMAND_SUBTYPE_NAMES from '../../../constants/CAVC_REMAND_SUBTYPE_NAMES';
import CAVC_DECISION_TYPES from '../../../constants/CAVC_DECISION_TYPES';
import CAVC_DECISION_TYPE_NAMES from '../../../constants/CAVC_DECISION_TYPE_NAMES';

import QueueFlowPage from '../components/QueueFlowPage';
import { requestSave, showErrorMessage } from '../uiReducer/uiActions';
import { validateDateNotInFuture } from '../../intake/util/issues';
import TextField from '../../components/TextField';
import RadioField from '../../components/RadioField';
import DateSelector from '../../components/DateSelector';
import Checkbox from '../../components/Checkbox';
import CheckboxGroup from '../../components/CheckboxGroup';
import TextareaField from '../../components/TextareaField';
import Button from '../../components/Button';
import SearchableDropdown from '../../components/SearchableDropdown';
import Alert from '../../components/Alert';
import { withRouter } from 'react-router';
import { SUBSTITUTE_DATE_ERRORS } from '../../intake/constants';
import { appealWithDetailSelector } from '../selectors';

import {
  JmrJmprIssuesBanner,
  MdrBanner,
  MdrIssuesBanner,
  NoMandateBanner,
} from './Alerts';

const radioLabelStyling = css({ marginTop: '2.5rem' });
const buttonStyling = css({ paddingLeft: '0' });
const issueListStyling = css({ marginTop: '0rem' });

const judgeOptions = _.map(CAVC_JUDGE_FULL_NAMES, (value) => ({
  label: value,
  value
}));

const attorneyOptions = [
  { displayText: 'Yes',
    value: '1' },
  { displayText: 'No',
    value: '2' },
];

const typeOptions = _.map(_.keys(CAVC_DECISION_TYPE_NAMES), (key) => ({
  displayText: CAVC_DECISION_TYPE_NAMES[key],
  value: key
}));

const isMandateProvidedOptions = [
  { displayText: 'Yes',
    value: 'true' },
  { displayText: 'No',
    value: 'false' }
];

const subTypeOptions = _.map(_.keys(CAVC_REMAND_SUBTYPE_NAMES), (key) => ({
  displayText: CAVC_REMAND_SUBTYPE_NAMES[key],
  value: key
}));

/**
 * @param {Object} props
 *  - @param {string}   appealId         The id of the appeal we are creating this cavc remand for. Used to grab
 *                                       associated decision issues on the appeal from state
 *  - @param {Object[]} decisionIssues   Issues pulled from state to allow the user to select which are being remanded
 *  - @param {Object}   error            Error sent from the back end upon submit to be displayed rather than submitting
 *  - @param {boolean}  highlightInvalid Whether or not to show field validation, set to true upon submit
 *  - @param {Object}   history          Provided with react router to be able to route to another page upon success
 *  - @param {Object}   featureToggles   Which cavc decision types and remand subtypes are supported
 */
const AddCavcRemandView = (props) => {
  const {
    appealId,
    decisionIssues,
    substituteAppellantClaimantOptions,
    error,
    highlightInvalid,
    history,
    featureToggles,
    ...otherProps
  } = props;
  const [docketNumber, setDocketNumber] = useState(null);
  const [attorney, setAttorney] = useState('1');
  const [isAppellantSubstituted, setIsAppellantSubstituted] = useState('false');
  const [appellantSubstitutionGrantedDate, setAppellantSubstitutionGrantedDate] = useState(null);
  const [participantId, setParticipantId] = useState(null);
  const [judge, setJudge] = useState(null);
  const [type, setType] = useState(CAVC_DECISION_TYPES.remand);
  const [subType, setSubType] = useState(CAVC_REMAND_SUBTYPES.jmr_jmpr);
  const [decisionDate, setDecisionDate] = useState(null);
  const [judgementDate, setJudgementDate] = useState(null);
  const [mandateDate, setMandateDate] = useState(null);
  // issues is a hash keyed on decisionIssue.id with boolean values indicating checkbox state
  const [issues, setIssues] = useState({});
  const [federalCircuit, setFederalCircuit] = useState(false);
  const [instructions, setInstructions] = useState('');
  const [isMandateProvided, setMandateProvided] = useState('true');
  const [isMandateSame, setMandateSame] = useState(true);
  const supportedDecisionTypes = {
    [CAVC_DECISION_TYPES.remand]: true,
    [CAVC_DECISION_TYPES.straight_reversal]: featureToggles.reversal_cavc_remand,
    [CAVC_DECISION_TYPES.death_dismissal]: featureToggles.dismissal_cavc_remand,
    // feature toggle AC requests that options are HIDDEN if toggle is enabled; hence the NOT operator (!)
    [CAVC_DECISION_TYPES.other_dismissal]: !featureToggles.cavc_dashboard_workflow,
    [CAVC_DECISION_TYPES.affirmed]: !featureToggles.cavc_dashboard_workflow,
    [CAVC_DECISION_TYPES.settlement]: !featureToggles.cavc_dashboard_workflow
  };
  const supportedRemandTypes = {
    [CAVC_REMAND_SUBTYPES.jmr]: false,
    [CAVC_REMAND_SUBTYPES.jmpr]: false,
    [CAVC_REMAND_SUBTYPES.jmr_jmpr]: true,
    [CAVC_REMAND_SUBTYPES.mdr]: featureToggles.mdr_cavc_remand
  };
  const filteredDecisionTypes = typeOptions.filter((typeOption) => supportedDecisionTypes[typeOption.value]);
  // filter out options that do not have a corresponding feature toggle toggled on
  const filteredRemandTypes = subTypeOptions.filter((subTypeOption) => supportedRemandTypes[subTypeOption.value]);

  const issueOptions = () => decisionIssues.map((decisionIssue) => ({
    id: decisionIssue.id.toString(),
    label: decisionIssue.description
  }));

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  // These values will be used in the "key details" section
  const nodDate = useMemo(() => parseISO(appeal.nodDate), [appeal.nodDate]);
  const dateOfDeath = useMemo(() => {
    const dod = appeal.veteranDateOfDeath;

    return dod ? parseISO(dod) : null;
  }, [appeal.veteranInfo]);

  const claimantOptionsExists =
    Array.isArray(substituteAppellantClaimantOptions) && substituteAppellantClaimantOptions.length > 0;

  const isAppellantSubstitutedOptions = [
    { displayText: 'Yes',
      value: 'true',
      disabled: !claimantOptionsExists
    },
    { displayText: 'No',
      value: 'false' }
  ];

  // returns ids of issues that are currently selected
  const selectedIssueIds = useMemo(() => {
    return Object.entries(issues).filter((item) => item[1]).
      flatMap((item) => item[0]);
  }, [issues]);

  // populates all checkboxes
  const selectAllIssues = () => {
    const checked = selectedIssueIds.length === 0;
    const newValues = {};

    issueOptions().forEach((item) => newValues[item.id] = checked);
    setIssues(newValues);
  };

  const allIssuesUnselected = useMemo(() => Object.values(issues).every((isChecked) => !isChecked), [issues]);

  // populate all issues checkboxes on initial render
  useEffect(() => selectAllIssues(), []);

  // update judgement and mandate dates every time isMandateSame or decisionDate is changed
  useEffect(() => {
    setJudgementDate(isMandateSame ? decisionDate : '');
    setMandateDate(isMandateSame ? decisionDate : '');
  }, [isMandateSame, decisionDate]);

  const onIssueChange = (evt) => {
    setIssues({ ...issues, [evt.target.name]: evt.target.checked });
  };

  const remandType = () => type === CAVC_DECISION_TYPES.remand;
  const straightReversalType = () => type === CAVC_DECISION_TYPES.straight_reversal;
  const deathDismissalType = () => type === CAVC_DECISION_TYPES.death_dismissal;
  const otherDismissalType = () => type === CAVC_DECISION_TYPES.other_dismissal;
  const affirmedType = () => type === CAVC_DECISION_TYPES.affirmed;
  const settlementType = () => type === CAVC_DECISION_TYPES.settlement;

  const jmrjmprSubtype = () => remandType() && subType === CAVC_REMAND_SUBTYPES.jmr_jmpr;
  const mdrSubtype = () => remandType() && subType === CAVC_REMAND_SUBTYPES.mdr;
  const mandateAvailable = () => !mdrSubtype() && (isMandateProvided === 'true');

  // update isMandateSame when new decision types are chosen. Previous functionality remains if old types are checked
  useEffect(() => {
    if (otherDismissalType() || affirmedType() || settlementType()) {
      setMandateSame(false);
    } else {
      setMandateSame(true);
    }
  }, [type]);

  // We accept ‐ HYPHEN, - Hyphen-minus, − MINUS SIGN, – EN DASH, — EM DASH
  const validDocketNumber = () => (/^\d{2}[-‐−–—]\d{1,5}$/).exec(docketNumber);
  const validJudge = () => Boolean(judge);
  const validDecisionDate = () => Boolean(decisionDate) && validateDateNotInFuture(decisionDate);

  const validDecisionIssues = () => selectedIssueIds?.length > 0;
  const issueSelectionError = () => COPY.CAVC_NO_ISSUES_ERROR;

  const validJudgementDate = () =>
    (Boolean(judgementDate) && validateDateNotInFuture(judgementDate)) || !mandateAvailable();
  const validMandateDate = () =>
    (Boolean(mandateDate) && validateDateNotInFuture(mandateDate)) || !mandateAvailable();
  const dates = [nodDate, dateOfDeath].filter(Boolean).map((date) => (isDate(date) ? date : parseISO(date)));
  const [minSubstitutionDateError, setMinSubstitutionDateError] = useState(false);
  const [futureSubstitutionDateError, setFutureSubstitutionDateError] = useState(false);

  const validateDateNotInPriorNodOrDod = (date) => {
    if (parseISO(date) < max(dates)) {
      return false;
    }

    return true;
  };

  const onSubstitutionDateChange = (val) => {
    setAppellantSubstitutionGrantedDate(val);

    if (!validateDateNotInPriorNodOrDod(val)) {
      setMinSubstitutionDateError(true);
      setFutureSubstitutionDateError(false);
    } else if (!validateDateNotInFuture(val)) {
      setMinSubstitutionDateError(false);
      setFutureSubstitutionDateError(true);
    } else {
      setMinSubstitutionDateError(false);
      setFutureSubstitutionDateError(false);
    }
  };

  const validAppellantSubstitutionGrantedDateDate = () => {
    return (!featureToggles.cavc_remand_granted_substitute_appellant ||
      isAppellantSubstituted === 'false' ||
      (isAppellantSubstituted === 'true' && Boolean(appellantSubstitutionGrantedDate) &&
        !futureSubstitutionDateError && !minSubstitutionDateError
      )
    );
  };

  const validSubstituteAppellantClaimant = () =>
    (!featureToggles.cavc_remand_granted_substitute_appellant ||
      isAppellantSubstituted === 'false' ||
      (isAppellantSubstituted === 'true' && Boolean(participantId))
    );

  const validInstructions = () => instructions && instructions.length > 0;

  const validateForm = () => {
    return validDocketNumber() && validJudge() && validDecisionDate() &&
    validJudgementDate() && validMandateDate() && validInstructions() &&
    validDecisionIssues() && validAppellantSubstitutionGrantedDateDate() && validSubstituteAppellantClaimant();
  };

  const mandateDatesPopulated = () => mandateAvailable() && Boolean(judgementDate) && Boolean(mandateDate);

  const successMsgDetail = () => {
    if (straightReversalType() || deathDismissalType()) {
      if (mandateDatesPopulated()) {
        return COPY.CAVC_REMAND_CASE_READY_FOR_DISTRIBUTION_DETAIL;
      }

      return COPY.CAVC_REMAND_MANDATE_HOLD_CREATED_DETAIL;
    } else if (mdrSubtype()) {
      return COPY.CAVC_REMAND_MDR_CREATED_DETAIL;
    } else if (otherDismissalType() || affirmedType() || settlementType()) {
      return null;
    }

    return COPY.CAVC_REMAND_CREATED_DETAIL;
  };

  const successMsgTitle = () => {
    if (straightReversalType() || deathDismissalType()) {
      if (mandateDatesPopulated()) {
        return COPY.CAVC_REMAND_CREATED_FOR_DISTRIBUTION_TITLE;
      }

      return COPY.CAVC_REMAND_CREATED_ON_HOLD_TITLE;
    } else if (otherDismissalType() || affirmedType() || settlementType()) {
      return COPY.CAVC_DASHBOARD_ENTRY_CREATED_TITLE;
    }

    return COPY.CAVC_REMAND_CREATED_TITLE;
  };

  const substitutionDateErrormsg = () => {
    if (minSubstitutionDateError) {
      return `${SUBSTITUTE_DATE_ERRORS.min_date_error} - ${format(new Date(max(dates)), 'MM/dd/yyyy')}`;
    } else if (futureSubstitutionDateError) {
      return SUBSTITUTE_DATE_ERRORS.in_future;
    }

    return SUBSTITUTE_DATE_ERRORS.invalid;
  };

  const submit = () => {
    const payload = {
      data: {
        judgement_date:
          ((remandType() && mdrSubtype()) || !mandateAvailable()) ? null : judgementDate,
        mandate_date: ((remandType() && mdrSubtype()) || !mandateAvailable()) ? null : mandateDate,
        source_appeal_id: appealId,
        cavc_docket_number: docketNumber,
        cavc_judge_full_name: judge.value,
        cavc_decision_type: type,
        decision_date: decisionDate,
        remand_subtype: remandType() ? subType : null,
        represented_by_attorney: attorney === '1',
        is_appellant_substituted:
          featureToggles.cavc_remand_granted_substitute_appellant ? isAppellantSubstituted : null,
        participant_id: featureToggles.cavc_remand_granted_substitute_appellant ? participantId : null,
        substitution_date:
          featureToggles.cavc_remand_granted_substitute_appellant ? appellantSubstitutionGrantedDate : null,
        remand_source: 'Add',
        decision_issue_ids: selectedIssueIds,
        federal_circuit: mdrSubtype() ? federalCircuit : null,
        instructions
      }
    };

    const successMsg = {
      title: successMsgTitle(),
      detail: successMsgDetail()
    };

    props.requestSave(`/appeals/${appealId}/cavc_remand`, payload, successMsg).
      // then((resp) => history.replace(`/queue/appeals/${resp.body.cavc_appeal.uuid}`)).
      then((resp) => {
        const pushHistoryUrl = resp.body.cavc_appeal ?
          `/queue/appeals/${resp.body.cavc_appeal.uuid}` : `/queue/appeals/${appealId}`;

        history.replace(pushHistoryUrl);
      }).
      catch((err) => props.showErrorMessage({ title: 'Error', detail: JSON.parse(err.message).errors[0].detail }));
  };

  const handleChangeIsAppellantSubstituted = (value) => {
    setIsAppellantSubstituted(value);
    setAppellantSubstitutionGrantedDate(null);
    setParticipantId(null);
  };

  const docketNumberField = <TextField
    label={COPY.CAVC_DOCKET_NUMBER_LABEL}
    name="docket-number"
    value={docketNumber}
    onChange={setDocketNumber}
    errorMessage={highlightInvalid && !validDocketNumber() ? COPY.CAVC_DOCKET_NUMBER_ERROR : null}
    strongLabel
  />;

  const isAppellantSubstitutedField = <RadioField
    label={COPY.CAVC_SUBSTITUTE_APPELLANT_LABEL}
    name="is-appellant-substituted"
    options={isAppellantSubstitutedOptions}
    value={isAppellantSubstituted}
    onChange={(val) => handleChangeIsAppellantSubstituted(val)}
    strongLabel
  />;

  const appellantSubstitutionGrantedField = <DateSelector
    label={COPY.CAVC_SUBSTITUTE_APPELLANT_DATE_LABEL}
    type="date"
    name="appellant-substitution-granted-date"
    value={appellantSubstitutionGrantedDate}
    onChange={(val) => onSubstitutionDateChange(val)}
    errorMessage={highlightInvalid &&
      !validAppellantSubstitutionGrantedDateDate() ? substitutionDateErrormsg() : null}
    strongLabel
  />;

  const substituteAppellantClaimantField = <RadioField
    label={COPY.CAVC_SUBSTITUTE_APPELLANT_CLAIMANTS_LABEL}
    name="substitute-appellant-claimant-options"
    options={substituteAppellantClaimantOptions}
    value={participantId}
    onChange={(val) => setParticipantId(val)}
    errorMessage={highlightInvalid &&
      !validSubstituteAppellantClaimant() ? COPY.CAVC_SUBSTITUTE_APPELLANT_CLAIMANTS_ERROR : null}
    strongLabel
  />;

  const representedField = <RadioField
    label={COPY.CAVC_ATTORNEY_LABEL}
    name="attorney-options"
    options={attorneyOptions}
    value={attorney}
    onChange={(val) => setAttorney(val)}
    strongLabel
  />;

  const judgeField = <SearchableDropdown
    name="judge-dropdown"
    label={COPY.CAVC_JUDGE_LABEL}
    searchable
    value={judge}
    onChange={(val) => setJudge(val)}
    options={judgeOptions}
    errorMessage={highlightInvalid && !validJudge() ? COPY.CAVC_JUDGE_ERROR : null}
    strongLabel
  />;

  const typeField = <RadioField
    styling={radioLabelStyling}
    label={COPY.CAVC_TYPE_LABEL}
    name="type-options"
    options={filteredDecisionTypes}
    value={type}
    onChange={(val) => setType(val)}
    strongLabel
    vertical
  />;

  const remandTypeField = <RadioField
    styling={radioLabelStyling}
    label={COPY.CAVC_SUB_TYPE_LABEL}
    name="sub-type-options"
    options={filteredRemandTypes}
    value={subType}
    onChange={(val) => setSubType(val)}
    strongLabel
    vertical
  />;

  const mandateDatesSameField = <>
    <legend><strong>{COPY.CAVC_REMAND_MANDATE_DATES_LABEL}</strong></legend>
    <Checkbox
      label={COPY.CAVC_REMAND_MANDATE_DATES_SAME_DESCRIPTION}
      name="mandate-dates-same-toggle"
      value={isMandateSame}
      onChange={(val) => setMandateSame(val)}
    />
  </>;

  const mandateProvidedField = <RadioField
    styling={radioLabelStyling}
    label={COPY.CAVC_REMAND_MANDATE_QUESTION}
    name="remand-provided-toggle"
    options={isMandateProvidedOptions}
    value={isMandateProvided}
    onChange={(val) => setMandateProvided(val)}
    strongLabel
  />;

  const decisionField = <DateSelector
    label={COPY.CAVC_COURT_DECISION_DATE}
    type="date"
    name="decision-date"
    value={decisionDate}
    onChange={(val) => setDecisionDate(val)}
    errorMessage={highlightInvalid && !validDecisionDate() ? COPY.CAVC_DECISION_DATE_ERROR : null}
    strongLabel
  />;

  const judgementField = <DateSelector
    label={COPY.CAVC_JUDGEMENT_DATE}
    type="date"
    name="judgement-date"
    value={judgementDate}
    onChange={(val) => setJudgementDate(val)}
    errorMessage={(highlightInvalid && !validJudgementDate() && !isMandateSame) ? COPY.CAVC_JUDGEMENT_DATE_ERROR : null}
    strongLabel
  />;

  const mandateField = <DateSelector
    label={COPY.CAVC_MANDATE_DATE}
    type="date"
    name="mandate-date"
    value={mandateDate}
    onChange={(val) => setMandateDate(val)}
    errorMessage={(highlightInvalid && !validMandateDate() && !isMandateSame) ? COPY.CAVC_MANDATE_DATE_ERROR : null}
    strongLabel
  />;

  const issuesField = <React.Fragment>
    <legend><strong>{COPY.CAVC_ISSUES_LABEL}</strong></legend>
    <Button
      name={selectedIssueIds.length ? 'Unselect all' : 'Select all'}
      styling={buttonStyling}
      linkStyling
      onClick={selectAllIssues}
    />
    <CheckboxGroup
      name="issuesList"
      hideLabel
      styling={issueListStyling}
      options={issueOptions()}
      values={issues}
      onChange={(val) => onIssueChange(val)}
      errorMessage={highlightInvalid && !validDecisionIssues() ? issueSelectionError() : null}
    />
  </React.Fragment>;

  const federalCircuitField = <React.Fragment>
    <legend><strong>{COPY.CAVC_FEDERAL_CIRCUIT_HEADER}</strong></legend>
    <Checkbox name="federalCircuit" label={COPY.CAVC_FEDERAL_CIRCUIT_LABEL}
      value={federalCircuit}
      onChange={(evt) => setFederalCircuit(evt)}
    />
  </React.Fragment>;

  const instructionsField = <TextareaField
    label={COPY.CAVC_INSTRUCTIONS_LABEL}
    name="context-and-instructions-textBox"
    value={instructions}
    onChange={(val) => setInstructions(val)}
    errorMessage={highlightInvalid && !validInstructions() ? COPY.CAVC_INSTRUCTIONS_ERROR : null}
    strongLabel
  />;

  return (
    <QueueFlowPage
      appealId={appealId}
      goToNextStep={submit}
      validateForm={validateForm}
      continueBtnText="Submit"
      hideCancelButton
      {...otherProps}
    >
      <h1>{COPY.ADD_CAVC_PAGE_TITLE}</h1>
      <p>{COPY.ADD_CAVC_DESCRIPTION}</p>
      {error && <Alert title={error.title} type="error">{error.detail}</Alert>}
      {docketNumberField}
      {featureToggles.cavc_remand_granted_substitute_appellant && isAppellantSubstitutedField}
      {featureToggles.cavc_remand_granted_substitute_appellant && !claimantOptionsExists &&
       <p>No existing relationships were found.</p>
      }
      {featureToggles.cavc_remand_granted_substitute_appellant &&
        isAppellantSubstituted === 'true' &&
        appellantSubstitutionGrantedField}
      {featureToggles.cavc_remand_granted_substitute_appellant &&
        isAppellantSubstituted === 'true' &&
        substituteAppellantClaimantField}
      {representedField}
      {judgeField}
      {typeField}
      {remandType() && remandTypeField }
      {type !== CAVC_DECISION_TYPES.remand && mandateProvidedField }
      {decisionField}
      {mdrSubtype() && <MdrBanner /> }
      {mandateAvailable() && mandateDatesSameField }
      {mandateAvailable() && !isMandateSame && judgementField }
      {mandateAvailable() && !isMandateSame && mandateField }
      {!mandateAvailable() && type !== CAVC_DECISION_TYPES.remand && <NoMandateBanner /> }
      {!deathDismissalType() && !otherDismissalType() && !affirmedType() && !settlementType() && issuesField}
      {jmrjmprSubtype() && allIssuesUnselected && <JmrJmprIssuesBanner />}
      {mdrSubtype() && allIssuesUnselected && <MdrIssuesBanner />}
      {mdrSubtype() && federalCircuitField }
      {instructionsField}
    </QueueFlowPage>
  );
};

AddCavcRemandView.propTypes = {
  appealId: PropTypes.string,
  decisionIssues: PropTypes.array,
  substituteAppellantClaimantOptions: PropTypes.array,
  requestSave: PropTypes.func,
  showErrorMessage: PropTypes.func,
  error: PropTypes.object,
  featureToggles: PropTypes.shape({
    mdr_cavc_remand: PropTypes.bool,
    reversal_cavc_remand: PropTypes.bool,
    dismissal_cavc_remand: PropTypes.bool,
    cavc_remand_granted_substitute_appellant: PropTypes.bool,
    cavc_dashboard_workflow: PropTypes.bool
  }),
  highlightInvalid: PropTypes.bool,
  history: PropTypes.object,
};

const mapStateToProps = (state, ownProps) => ({
  decisionIssues: state.queue.appealDetails[ownProps.appealId].decisionIssues,
  substituteAppellantClaimantOptions: state.queue.appealDetails[ownProps.appealId].substituteAppellantClaimantOptions,
  highlightInvalid: state.ui.highlightFormItems,
  error: state.ui.messages.error,
  featureToggles: state.ui.featureToggles,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  showErrorMessage
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(AddCavcRemandView));
/* eslint-enable max-lines */
