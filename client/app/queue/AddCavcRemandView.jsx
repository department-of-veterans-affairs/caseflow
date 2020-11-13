import React, { useState, useEffect, useMemo } from 'react';
import { useSelector } from 'react-redux';
import { css } from 'glamor';
import classNames from 'classnames';
import PropTypes from 'prop-types';
import COPY from '../../COPY';

import QueueFlowPage from './components/QueueFlowPage';
import { appealWithDetailSelector } from './selectors';
import TextField from '../components/TextField';
import RadioField from '../components/RadioField';
import DateSelector from '../components/DateSelector';
import Checkbox from '../components/Checkbox';
import CheckboxGroup from '../components/CheckboxGroup';
import TextareaField from '../components/TextareaField';
import { JudgeDropdown } from '../components/DataDropdowns';
import Button from '../components/Button';
import Alert from '../components/Alert';
import { submitMTVAttyReview } from './mtv/mtvActions';

const labelStyling = css({ marginTop: '2.5rem' });
const buttonStyling = css({ paddingLeft: '0' });
const alertStyling = css({ width: '52rem' });

const attorneyOptions = [
  { displayText: 'Yes',
    value: '1' },
  { displayText: 'No',
    value: '2' },
];
const typeOptions = [
  { displayText: COPY.CAVC_REMAND,
    value: '1' },
  { displayText: COPY.CAVC_STRAIGHT_REVERSAL,
    value: '2' },
  { displayText: COPY.CAVC_DEATH_DISMISSAL,
    value: '3' }
];
const subTypeOptions = [
  { displayText: COPY.CAVC_JMR,
    value: '1' },
  { displayText: COPY.CAVC_JMPR,
    value: '2' },
  { displayText: COPY.CAVC_MDR,
    value: '3' }
];
const issueOptions = [
  { id: 'ratingIssue1',
    label: COPY.CAVC_RATING_ISSUE_1 },
  { id: 'ratingIssue2',
    label: COPY.CAVC_RATING_ISSUE_2 },
  { id: 'nonRatingIssue1',
    label: COPY.CAVC_NON_RATING_ISSUE_1 },
  { id: 'nonRatingIssue2',
    label: COPY.CAVC_NON_RATING_ISSUE_2 }
];

const AddCavcRemandView = (props) => {

  const [docketNumber, setDocketNumber] = useState(null);
  const [attorney, setAttorney] = useState('1');
  const [judge, setJudge] = useState(null);
  const [type, setType] = useState('1');
  const [subType, setSubType] = useState('1');
  const [decisionDate, setDecisionDate] = useState(null);
  const [judgementSelection, setJudgementSelection] = useState(true);
  const [judgementDate, setJudgementDate] = useState(null);
  const [mandateDate, setMandateDate] = useState(null);
  const [issues, setIssues] = useState({});
  const [text, setText] = useState(null);

  // determines which issues are currently selected
  const selectedIssues = useMemo(() => {
    return Object.entries(issues).filter((item) => item[1]).
      flatMap((item) => item[0]);
  }, [issues]);

  // populates all checkboxes when either JMR remand or Select all button is selected
  const toggleIssues = () => {
    const checked = selectedIssues.length === 0;
    const newValues = {};

    issueOptions.forEach((item) => newValues[item.id] = checked);
    setIssues(newValues);
  };

  // populate all of our checkboxes on initial render
  useEffect(() => toggleIssues(), []);

  // clears all decision issue checkboxes
  const clearAllIssues = () => {
    setIssues({});
  };

  // checks if the remand is JMR, if so it checks all decision issue checkboxes
  const checkSubType = (val) => {
    if (val === '1') {
      toggleIssues();
      setSubType(val);
    } else {
      clearAllIssues();
      setSubType(val);
    }
  };

  const onIssueChange = (evt) => {
    setIssues({ ...issues, [evt.target.name]: evt.target.checked });
  };

  // const submit = () => {
  //   const payload = { 
  //     data: { 
  //     judgement_date: judgementDate,

  //   } };
  // }

  return (
    <QueueFlowPage
      appealId={props.appealId}
      // goToNextStep={submit}
      continueBtnText="Submit"
      hideCancelButton
      // {...otherProps}
       >
      <h1>{COPY.ADD_CAVC_PAGE_TITLE}</h1>
      <p>{COPY.ADD_CAVC_DESCRIPTION}</p>
      <TextField
        name={<h4>{COPY.CAVC_DOCKET_NUMBER_LABEL}</h4>}
        value={docketNumber}
        onChange={setDocketNumber} />
      <RadioField
        label={<h4 id="horizontal-radio">{COPY.CAVC_ATTORNEY_LABEL}</h4>}
        name="attorney-options"
        options={attorneyOptions}
        value={attorney}
        onChange={(val) => setAttorney(val)} />
      <JudgeDropdown
        label={<h3>{COPY.CAVC_JUDGE_LABEL}</h3>}
        name="judge-dropdown"
        value={judge}
        onChange={(val) => setJudge(val)} />
      <RadioField
        label={<h3 {...labelStyling} id="vertical-radio">{COPY.CAVC_TYPE_LABEL}</h3>}
        name="type-options"
        options={typeOptions}
        value={type}
        onChange={(val) => setType(val)} />
      <RadioField
        label={<h3 {...labelStyling} id="vertical-radio">{COPY.CAVC_SUB_TYPE_LABEL}</h3>}
        name="sub-type-options"
        options={subTypeOptions}
        value={subType}
        onChange={(val) => checkSubType(val)} />
      <h4 {...labelStyling}>{COPY.CAVC_COURT_DECISION_DATE}</h4>
      <DateSelector
        type="date"
        value={decisionDate}
        onChange={(val) => setDecisionDate(val)} />
      {subType === '3' &&
        <Alert
          type="info"
          classname="usa-alert-slim"
          message={COPY.CAVC_MDR_MESSAGE}
          styling={alertStyling}
          lowerMargin />}
      <h3>{COPY.CAVC_JUDGEMENT_DATE_HEADER}</h3>
      <Checkbox
        label={COPY.CAVC_JUDGEMENT_DATE_DESC}
        name="judgement-decision-date"
        vertical
        value={judgementSelection}
        onChange={(val) => setJudgementSelection(val)} />
      <h4 {...labelStyling}>{COPY.CAVC_JUDGEMENT_DATE}</h4>
      {subType === '1' && !judgementSelection &&
      <>
        <DateSelector
          type="date"
          value={judgementDate}
          onChange={(val) => setJudgementDate(val)} />
        <h4 {...labelStyling}>{COPY.CAVC_MANDATE_DATE}</h4>
        <DateSelector
          type="date"
          value={mandateDate}
          onChange={(val) => setMandateDate(val)} />
      </> }
      <h3>{COPY.CAVC_ISSUES_LABEL}</h3>
      {subType !== '1' && (!selectedIssues.length || selectedIssues.length === issueOptions.length) && <Button
        name={selectedIssues.length ? 'Unselect all' : 'Select all'}
        styling={buttonStyling}
        linkStyling
        onClick={toggleIssues} />}
      <CheckboxGroup
        // label={<h3 id="vertical">{COPY.CAVC_ISSUES_LABEL}</h3>}
        // name="Rating Issues Checkboxes"
        options={issueOptions}
        values={issues}
        onChange={(val) => onIssueChange(val)}
        disableAll={subType === '1'} />
      {subType === '1' && <i>*Joint Motion for Remand (JMR) automatically selects all issues</i>}
      <TextareaField
        label={<h3 {...labelStyling}>{COPY.CAVC_INSTRUCTIONS_LABEL}</h3>}
        name="context-and-instructions-textBox"
        value={text}
        onChange={(val) => setText(val)} />
    </QueueFlowPage>
  );
};

AddCavcRemandView.propTypes = {
  appealId: PropTypes.string
};

export default AddCavcRemandView;
