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
import TextField from '../components/TextField';
import RadioField from '../components/RadioField';
import DateSelector from '../components/DateSelector';
import CheckboxGroup from '../components/CheckboxGroup';
import TextareaField from '../components/TextareaField';
import Button from '../components/Button';
import SearchableDropdown from '../components/SearchableDropdown';
import StringUtil from '../util/StringUtil';
import Alert from '../components/Alert';
import { withRouter } from 'react-router';

const radioLabelStyling = css({ marginTop: '2.5rem' });
const buttonStyling = css({ paddingLeft: '0' });

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
    value: '1' },
  { displayText: 'No',
    value: '2' }
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
  const [issues, setIssues] = useState({});
  const [instructions, setInstructions] = useState(null);
  const [isMandateProvided, setMandateProvided] = useState('1');

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
    id: decisionIssue.id,
    label: decisionIssue.description
  }));

  // determines which issues are currently selected
  const selectedIssues = useMemo(() => {
    return Object.entries(issues).filter((item) => item[1]).
      flatMap((item) => item[0]);
  }, [issues]);

  // populates all checkboxes
  const selectAllIssues = () => {
    const checked = selectedIssues.length === 0;
    const newValues = {};

    issueOptions().forEach((item) => newValues[item.id] = checked);
    setIssues(newValues);
  };

  // populate all of our checkboxes on initial render
  useEffect(() => selectAllIssues(), []);

  const onIssueChange = (evt) => {
    setIssues({ ...issues, [evt.target.name]: evt.target.checked });
  };

  const remandType = () => type === CAVC_DECISION_TYPES.remand;
  const straightReversalType = () => type === CAVC_DECISION_TYPES.straight_reversal;
  const deathDismissalType = () => type === CAVC_DECISION_TYPES.death_dismissal;
  const mdrSubtype = () => subType === CAVC_REMAND_SUBTYPES.mdr;
  const mandateAvailable = () => !(type === CAVC_DECISION_TYPES.remand && mdrSubtype()) && (isMandateProvided === '1');
  const validDocketNumber = () => (/^\d{2}-\d{1,5}$/).exec(docketNumber);
  const validJudge = () => Boolean(judge);
  const validDecisionDate = () => Boolean(decisionDate);
  const mandateNotRequired = () => straightReversalType() || deathDismissalType() || mdrSubtype();
  const validJudgementDate = () => Boolean(judgementDate) || mandateNotRequired();
  const validMandateDate = () => Boolean(mandateDate) || mandateNotRequired();
  const validInstructions = () => instructions && instructions.length > 0;

  const validateForm = () => {
    return validDocketNumber() && validJudge() && validDecisionDate() && validJudgementDate() && validMandateDate() &&
      validInstructions();
  };

  const successMsgDetail = () => {
    if (straightReversalType() || deathDismissalType()) {
      if (Boolean(judgementDate) && Boolean(mandateDate)) {
        return COPY.CAVC_REMAND_CASE_READY_FOR_DISTRIBUTION_DETAIL;
      }

      return COPY.CAVC_REMAND_MANDATE_HOLD_CREATED_DETAIL;
    } else if (remandType() && mdrSubtype()) {
      return COPY.CAVC_REMAND_MDR_CREATED_DETAIL;
    }

    return COPY.CAVC_REMAND_CREATED_DETAIL;
  };

  const successMsgTitle = () => {
    if (straightReversalType() || deathDismissalType()) {
      if (Boolean(judgementDate) && Boolean(mandateDate)) {
        return COPY.CAVC_REMAND_CREATED_FOR_DISTRIBUTION_TITLE;
      }

      return COPY.CAVC_REMAND_CREATED_ON_HOLD_TITLE;
    }

    return COPY.CAVC_REMAND_CREATED_TITLE;
  };

  const submit = () => {
    const payload = {
      data: {
        judgement_date: judgementDate,
        mandate_date: mandateDate,
        source_appeal_id: appealId,
        cavc_docket_number: docketNumber,
        cavc_judge_full_name: judge.value,
        cavc_decision_type: type,
        decision_date: decisionDate,
        remand_subtype: type === CAVC_DECISION_TYPES.remand ? subType : null,
        represented_by_attorney: attorney === '1',
        decision_issue_ids: selectedIssues,
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

  const mdrBanner = <Alert type="info" scrollOnAlert={false}>{COPY.MDR_SELECTION_ALERT_BANNER}</Alert>;

  const noMandateBanner = <Alert type="info" scrollOnAlert={false}>{COPY.CAVC_REMAND_NO_MANDATE_TEXT}</Alert>;

  const judgementField = <DateSelector
    label={COPY.CAVC_JUDGEMENT_DATE}
    type="date"
    name="judgement-date"
    value={judgementDate}
    onChange={(val) => setJudgementDate(val)}
    errorMessage={highlightInvalid && !validJudgementDate() ? COPY.CAVC_JUDGEMENT_DATE_ERROR : null}
    strongLabel
  />;

  const mandateField = <DateSelector
    label={COPY.CAVC_MANDATE_DATE}
    type="date"
    name="mandate-date"
    value={mandateDate}
    onChange={(val) => setMandateDate(val)}
    errorMessage={highlightInvalid && !validMandateDate() ? COPY.CAVC_MANDATE_DATE_ERROR : null}
    strongLabel
  />;

  const issuesField = <React.Fragment>
    <legend><strong>{COPY.CAVC_ISSUES_LABEL}</strong></legend>
    <Button
      name={selectedIssues.length ? 'Unselect all' : 'Select all'}
      styling={buttonStyling}
      linkStyling
      onClick={selectAllIssues}
    />
    <CheckboxGroup
      options={issueOptions()}
      values={issues}
      onChange={(val) => onIssueChange(val)}
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
      {type === CAVC_DECISION_TYPES.remand && remandTypeField }
      {!mdrSubtype() && type !== CAVC_DECISION_TYPES.remand && mandateProvidedField }
      {decisionField}
      {type === CAVC_DECISION_TYPES.remand && mdrSubtype() && mdrBanner }
      {mandateAvailable() && judgementField }
      {mandateAvailable() && mandateField }
      {!mandateAvailable() && type !== CAVC_DECISION_TYPES.remand && noMandateBanner }
      {issuesField}
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
