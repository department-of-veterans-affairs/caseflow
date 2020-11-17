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
import { requestSave } from './uiReducer/uiActions';
import TextField from '../components/TextField';
import RadioField from '../components/RadioField';
import DateSelector from '../components/DateSelector';
import CheckboxGroup from '../components/CheckboxGroup';
import TextareaField from '../components/TextareaField';
import Button from '../components/Button';
import SearchableDropdown from '../components/SearchableDropdown';
import StringUtil from '../util/StringUtil';

const labelStyling = css({ marginTop: '2.5rem' });
const buttonStyling = css({ paddingLeft: '0' });

const judgeOptions = [].concat(
  _.map(CAVC_JUDGE_FULL_NAMES, (value) => ({
    label: value,
    value
  }))
);

const attorneyOptions = [
  { displayText: 'Yes',
    value: '1' },
  { displayText: 'No',
    value: '2' },
];

const typeOptions = _.map(_.keys(CAVC_DECISION_TYPES), (key) => (
  { displayText: StringUtil.snakeCaseToCapitalized(key), value: key }
));

const subTypeOptions = _.map(_.keys(CAVC_REMAND_SUBTYPE_NAMES), (key) => (
  { displayText: CAVC_REMAND_SUBTYPE_NAMES[key], value: key }
));

const AddCavcRemandView = (props) => {

  const { decisionIssues, appealId, requestSave, ...otherProps } = props;

  const [docketNumber, setDocketNumber] = useState(null);
  const [attorney, setAttorney] = useState('1');
  const [judge, setJudge] = useState(null);
  const [type, setType] = useState(CAVC_DECISION_TYPES.remand);
  const [subType, setSubType] = useState(CAVC_REMAND_SUBTYPES.jmr);
  const [decisionDate, setDecisionDate] = useState(null);
  const [judgementDate, setJudgementDate] = useState(null);
  const [mandateDate, setMandateDate] = useState(null);
  const [issues, setIssues] = useState({});
  const [text, setText] = useState(null);

  const issueOptions = () => {
    const issueList = [];

    decisionIssues.map((decisionIssue) => {
      const issue = {
        id: decisionIssue.id,
        label: decisionIssue.description
      };

      return issueList.push(issue);
    });

    return issueList;
  };

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

  const submit = () => {
    const payload = {
      data: {
        judgement_date: judgementDate,
        mandate_date: mandateDate,
        appeal_id: appealId,
        cavc_docket_number: docketNumber,
        cavc_judge_full_name: judge.value,
        cavc_decision_type: type,
        decision_date: decisionDate,
        instructions: text,
        remand_subtype: subType,
        represented_by_attorney: attorney === '1',
        decision_issue_ids: decisionIssues.map((decisionIssue) => decisionIssue.id)
      } };

    const successMsg = {
      title: COPY.CAVC_REMAND_CREATED_TITLE,
      detail: COPY.CAVC_REMAND_CREATED_DETAIL
    };

    return requestSave(`/appeals/${appealId}/cavc_remand`, payload, successMsg).
      then((resp) => {
        console.log(resp);
      });
  };

  const docketNumberField = <TextField
    name={<h3>{COPY.CAVC_DOCKET_NUMBER_LABEL}</h3>}
    value={docketNumber}
    onChange={setDocketNumber}
  />;

  const representedField = <RadioField
    label={<h3 id="horizontal-radio">{COPY.CAVC_ATTORNEY_LABEL}</h3>}
    name="attorney-options"
    options={attorneyOptions}
    value={attorney}
    onChange={(val) => setAttorney(val)}
  />;

  const judgeField = <SearchableDropdown
    name="judge-dropdown"
    label={<h3>{COPY.CAVC_JUDGE_LABEL}</h3>}
    searchable
    value={judge}
    onChange={(val) => setJudge(val)}
    options={judgeOptions}
  />;

  const typeField = <RadioField
    label={<h3 {...labelStyling} id="vertical-radio">{COPY.CAVC_TYPE_LABEL}</h3>}
    name="type-options"
    options={typeOptions}
    value={type}
    onChange={(val) => setType(val)}
  />;

  const remandTypeField = <RadioField
    label={<h3 {...labelStyling} id="vertical-radio">{COPY.CAVC_SUB_TYPE_LABEL}</h3>}
    name="sub-type-options"
    options={subTypeOptions}
    value={subType}
    onChange={(val) => setSubType(val)}
  />;

  const decisionField = <React.Fragment>
    <h3 {...labelStyling}>{COPY.CAVC_COURT_DECISION_DATE}</h3>
    <DateSelector
      type="date"
      value={decisionDate}
      onChange={(val) => setDecisionDate(val)}
    />
  </React.Fragment>;

  const judgementField = <React.Fragment>
    <h3 {...labelStyling}>{COPY.CAVC_JUDGEMENT_DATE}</h3>
    <DateSelector
      type="date"
      value={judgementDate}
      onChange={(val) => setJudgementDate(val)}
    />
  </React.Fragment>;

  const mandateField = <React.Fragment>
    <h3 {...labelStyling}>{COPY.CAVC_MANDATE_DATE}</h3>
    <DateSelector
      type="date"
      value={mandateDate}
      onChange={(val) => setMandateDate(val)}
    />
  </React.Fragment>;

  const issuesField = <React.Fragment>
    <h3>{COPY.CAVC_ISSUES_LABEL}</h3>
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
    label={<h3 {...labelStyling}>{COPY.CAVC_INSTRUCTIONS_LABEL}</h3>}
    name="context-and-instructions-textBox"
    value={text}
    onChange={(val) => setText(val)}
  />;


  return (
    <QueueFlowPage
      appealId={appealId}
      goToNextStep={submit}
      continueBtnText="Submit"
      hideCancelButton
      {...otherProps} >
      <h1>{COPY.ADD_CAVC_PAGE_TITLE}</h1>
      <p>{COPY.ADD_CAVC_DESCRIPTION}</p>
      {docketNumberField}
      {representedField}
      {judgeField}
      {typeField}
      {type === CAVC_DECISION_TYPES.remand && remandTypeField }
      {decisionField}
      {judgementField}
      {mandateField}
      {issuesField}
      {instructionsField}
    </QueueFlowPage>
  );
};

AddCavcRemandView.propTypes = {
  appealId: PropTypes.string,
  decisionIssues: PropTypes.array,
  requestSave: PropTypes.func
};

const mapStateToProps = (state, ownProps) => ({
  decisionIssues: state.queue.appealDetails[ownProps.appealId].decisionIssues
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AddCavcRemandView);
