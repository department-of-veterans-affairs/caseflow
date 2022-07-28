import React, { useState } from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { css } from 'glamor';

import SplitAppealProgressBar from '../components/SplitAppealProgressBar';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import Checkbox from '../../components/Checkbox';
import CheckboxGroup from '../../components/CheckboxGroup';

import COPY from '../../../COPY.json';
import SPLIT_APPEAL_REASONS from '../../../constants/SPLIT_APPEAL_REASONS';
import _ from 'lodash';
import PropTypes from 'prop-types';

const issueListStyling = css({ marginTop: '0rem' });

const SplitAppealView = (props) => {
  const { serverIntake } = props;

  const requestIssues = serverIntake.requestIssues;
  console.log(requestIssues);

  const [reason, setReason] = useState(null);
  const [selectedIssues, setSelectedIssues] = useState({});

  const reasonOptions = _.map(SPLIT_APPEAL_REASONS, (value) => ({
    label: value,
    value
  }));

  const getDisplayOptions = (issues = []) => {
    // CheckboxGroup expects options with id (string) & label
    console.log(issues);
    
    return issues.map(({ id, description, benefit_type, approx_decision_date }, idx) => ({ id: id.toString(),
      label: `${description}` + '\nBenefit Type:' }));
  };

  const issueOptions = () => requestIssues.map((issue) => ({
    id: issue.id.toString(),
    label:
      <>
        <span>{issue.description}</span><br />
        <span>Benefit Type: {issue.benefit_type}</span><br />
        <span>Decision Date: {issue.approx_decision_date}</span>
      </>
  }));
 
  return (
    <>
      <h1>{COPY.SPLIT_APPEAL_CREATE_TITLE}</h1>
      <span>{COPY.SPLIT_APPEAL_CREATE_SUBHEAD}</span>

      <br /><br />
      <SearchableDropdown
        name="splitAppealReasonDropdown"
        label={COPY.SPLIT_APPEAL_CREATE_REASONING_TITLE}
        strongLabel
        value={reason}
        onChange={(selection) => setReason(selection.value)}
        options={reasonOptions}
      />
      <br />
      {reason === 'Other' && (
        <TextareaField
          name="reason"
          label="Reason for split"
          id="otherReason"
          textAreaStyling={css({ height: '50px' })}
          maxlength={350}
          characterLimitTopRight
          optional
        />
      )}
      <br />

      <CheckboxGroup
        vertical
        name="issues"
        label={COPY.SPLIT_APPEAL_CREATE_SELECT_ISSUES_TITLE}
        // onChange={(event) => {
        //   setSelectedIssues((prevVals) => ({
        //     ...prevVals,
        //     [event.target.getAttribute('id')]: event.target.checked
        //   }));
        // }}
        // value={selectedIssues}
        // options={getDisplayOptions(requestIssues)}
        options={issueOptions()}
        styling={issueListStyling}
        strongLabel
      />
    </>
  );
};

SplitAppealView.propTypes = {
  serverIntake: PropTypes.object
};

export default SplitAppealView;
