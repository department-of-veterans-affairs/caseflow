import React, { useState, useEffect, useMemo } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';
import PropTypes from 'prop-types';
import COPY from '../../COPY';
import CAVC_JUDGE_FULL_NAMES from '../../constants/CAVC_JUDGE_FULL_NAMES';
import CAVC_REMAND_SUBTYPES from '../../constants/CAVC_REMAND_SUBTYPES';
import CAVC_REMAND_SUBTYPE_NAMES from '../../constants/CAVC_REMAND_SUBTYPE_NAMES';
import CAVC_DECISION_TYPES from '../../constants/CAVC_DECISION_TYPES';

import QueueFlowPage from './components/QueueFlowPage';
import { requestSave, showErrorMessage } from './uiReducer/uiActions';
import { validateDateNotInFuture } from '../intake/util/issues';
import TextField from '../components/TextField';
import RadioField from '../components/RadioField';
import DateSelector from '../components/DateSelector';
import Checkbox from '../components/Checkbox';
import CheckboxGroup from '../components/CheckboxGroup';
import TextareaField from '../components/TextareaField';
import Button from '../components/Button';
import SearchableDropdown from '../components/SearchableDropdown';
import StringUtil from '../util/StringUtil';
import Alert from '../components/Alert';
import { withRouter } from 'react-router';

const radioLabelStyling = css({ marginTop: '2.5rem' });
const buttonStyling = css({ paddingLeft: '0' });
const bottomInfoStyling = css({ marginBottom: '4rem' });
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

const typeOptions = _.map(_.keys(CAVC_DECISION_TYPES), (key) => ({
  displayText: StringUtil.snakeCaseToCapitalized(key),
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
  const { appealId, decisionIssues, error, highlightInvalid, history, featureToggles, ...otherProps } = props;

  const [docketNumber, setDocketNumber] = useState(null);
  const [attorney, setAttorney] = useState('1');
  const [judge, setJudge] = useState(null);
  const [type, setType] = useState(CAVC_DECISION_TYPES.remand);
  const [subType, setSubType] = useState(CAVC_REMAND_SUBTYPES.jmr);
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
    [CAVC_DECISION_TYPES.remand]: featureToggles.cavc_remand,
    [CAVC_DECISION_TYPES.straight_reversal]: featureToggles.reversal_cavc_remand,
    [CAVC_DECISION_TYPES.death_dismissal]: featureToggles.dismissal_cavc_remand
  };
  const supportedRemandTypes = {
    [CAVC_REMAND_SUBTYPES.jmr]: featureToggles.cavc_remand,
    [CAVC_REMAND_SUBTYPES.jmpr]: featureToggles.cavc_remand,
    [CAVC_REMAND_SUBTYPES.mdr]: featureToggles.mdr_cavc_remand
  };
  const filteredDecisionTypes = typeOptions.filter((typeOption) => supportedDecisionTypes[typeOption.value]);
  // filter out options that do not have a corresponding feature toggle toggled on
  const filteredRemandTypes = subTypeOptions.filter((subTypeOption) => supportedRemandTypes[subTypeOption.value]);

  const issueOptions = () => decisionIssues.map((decisionIssue) => ({
    id: decisionIssue.id.toString(),
    label: decisionIssue.description
  }));

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

  const allIssuesSelected = useMemo(() => Object.values(issues).every((isChecked) => isChecked), [issues]);
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

  const jmrSubtype = () => remandType() && subType === CAVC_REMAND_SUBTYPES.jmr;
  const jmprSubtype = () => remandType() && subType === CAVC_REMAND_SUBTYPES.jmpr;
  const mdrSubtype = () => remandType() && subType === CAVC_REMAND_SUBTYPES.mdr;
  const mandateAvailable = () => !mdrSubtype() && (isMandateProvided === 'true');

  // We accept ‐ HYPHEN, - Hyphen-minus, − MINUS SIGN, – EN DASH, — EM DASH
  const validDocketNumber = () => (/^\d{2}[-‐−–—]\d{1,5}$/).exec(docketNumber);
  const validJudge = () => Boolean(judge);
  const validDecisionDate = () => Boolean(decisionDate) && validateDateNotInFuture(decisionDate);

  const validDecisionIssues = () => jmrSubtype() ? allIssuesSelected : selectedIssueIds?.length > 0;
  const issueSelectionError = () =>
    (jmrSubtype() && !allIssuesSelected) ? COPY.CAVC_ALL_ISSUES_ERROR : COPY.CAVC_NO_ISSUES_ERROR;

  const validJudgementDate = () =>
    (Boolean(judgementDate) && validateDateNotInFuture(judgementDate)) || !mandateAvailable();
  const validMandateDate = () =>
    (Boolean(mandateDate) && validateDateNotInFuture(mandateDate)) || !mandateAvailable();

  const validInstructions = () => instructions && instructions.length > 0;

  const validateForm = () => {
    return validDocketNumber() && validJudge() && validDecisionDate() && validJudgementDate() && validMandateDate() &&
      validInstructions() && validDecisionIssues();
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
    }

    return COPY.CAVC_REMAND_CREATED_DETAIL;
  };

  const successMsgTitle = () => {
    if (straightReversalType() || deathDismissalType()) {
      if (mandateDatesPopulated()) {
        return COPY.CAVC_REMAND_CREATED_FOR_DISTRIBUTION_TITLE;
      }

      return COPY.CAVC_REMAND_CREATED_ON_HOLD_TITLE;
    }

    return COPY.CAVC_REMAND_CREATED_TITLE;
  };

  const submit = () => {
    const payload = {
      data: {
        judgement_date: ((remandType() && mdrSubtype()) || !mandateAvailable()) ? null : judgementDate,
        mandate_date: ((remandType() && mdrSubtype()) || !mandateAvailable()) ? null : mandateDate,
        source_appeal_id: appealId,
        cavc_docket_number: docketNumber,
        cavc_judge_full_name: judge.value,
        cavc_decision_type: type,
        decision_date: decisionDate,
        remand_subtype: remandType() ? subType : null,
        represented_by_attorney: attorney === '1',
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
      then((resp) => history.replace(`/queue/appeals/${resp.body.cavc_appeal.uuid}`)).
      catch((err) => props.showErrorMessage({ title: 'Error', detail: JSON.parse(err.message).errors[0].detail }));
  };

  const docketNumberField = <TextField
    label={COPY.CAVC_DOCKET_NUMBER_LABEL}
    name="docket-number"
    value={docketNumber}
    onChange={setDocketNumber}
    errorMessage={highlightInvalid && !validDocketNumber() ? COPY.CAVC_DOCKET_NUMBER_ERROR : null}
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

  const jmrIssuesBanner = <Alert type="info" styling={bottomInfoStyling} scrollOnAlert={false}>
    {COPY.JMR_SELECTION_ISSUE_INFO_BANNER}
  </Alert>;
  const jmprIssuesBanner = <Alert type="info" styling={bottomInfoStyling} scrollOnAlert={false}>
    {COPY.JMPR_SELECTION_ISSUE_INFO_BANNER}
  </Alert>;
  const mdrIssuesBanner = <Alert type="info" styling={bottomInfoStyling} scrollOnAlert={false}>
    {COPY.MDR_SELECTION_ISSUE_INFO_BANNER}
  </Alert>;

  const mdrBanner = <Alert type="info" styling={bottomInfoStyling} scrollOnAlert={false}>
    {COPY.MDR_SELECTION_ALERT_BANNER}
  </Alert>;
  const noMandateBanner = <Alert type="info" styling={bottomInfoStyling} scrollOnAlert={false}>
    {COPY.CAVC_REMAND_NO_MANDATE_TEXT}
  </Alert>;

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
      {representedField}
      {judgeField}
      {typeField}
      {remandType() && remandTypeField }
      {type !== CAVC_DECISION_TYPES.remand && mandateProvidedField }
      {decisionField}
      {mdrSubtype() && mdrBanner }
      {mandateAvailable() && mandateDatesSameField }
      {mandateAvailable() && !isMandateSame && judgementField }
      {mandateAvailable() && !isMandateSame && mandateField }
      {!mandateAvailable() && type !== CAVC_DECISION_TYPES.remand && noMandateBanner }
      {!deathDismissalType() && issuesField}
      {jmrSubtype() && !allIssuesSelected && jmrIssuesBanner}
      {jmprSubtype() && allIssuesUnselected && jmprIssuesBanner}
      {mdrSubtype() && allIssuesUnselected && mdrIssuesBanner}
      {mdrSubtype() && federalCircuitField }
      {instructionsField}
    </QueueFlowPage>
  );
};

AddCavcRemandView.propTypes = {
  appealId: PropTypes.string,
  decisionIssues: PropTypes.array,
  requestSave: PropTypes.func,
  showErrorMessage: PropTypes.func,
  error: PropTypes.object,
  featureToggles: PropTypes.shape({
    cavc_remand: PropTypes.bool,
    mdr_cavc_remand: PropTypes.bool,
    reversal_cavc_remand: PropTypes.bool,
    dismissal_cavc_remand: PropTypes.bool
  }),
  highlightInvalid: PropTypes.bool,
  history: PropTypes.object
};

const mapStateToProps = (state, ownProps) => ({
  decisionIssues: state.queue.appealDetails[ownProps.appealId].decisionIssues,
  highlightInvalid: state.ui.highlightFormItems,
  error: state.ui.messages.error,
  featureToggles: state.ui.featureToggles
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  showErrorMessage
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(AddCavcRemandView));
