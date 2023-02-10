import React, { useContext } from 'react';
import { css } from 'glamor';

import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import CheckboxGroup from '../../components/CheckboxGroup';

import COPY from '../../../COPY';
import SPLIT_APPEAL_REASONS from '../../../constants/SPLIT_APPEAL_REASONS';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import _ from 'lodash';
import PropTypes from 'prop-types';
import { formatDateStr } from '../../util/DateUtil';
import { StateContext } from '../../intakeEdit/IntakeEditFrame';
const issueListStyling = css({ marginTop: '0rem', marginLeft: '6rem' });

const SplitAppealView = (props) => {
  const {
    reason,
    setReason,
    otherReason,
    setOtherReason,
    selectedIssues,
    setSelectedIssues
  } = useContext(StateContext);
  const { serverIntake } = props;

  const requestIssues = serverIntake.requestIssues;

  const onIssueChange = (evt) => {
    setSelectedIssues({ ...selectedIssues, [evt.target.name]: evt.target.checked });
  };

  const onReasonChange = (selection) => {
    setReason(selection.value);
  };

  const onOtherReasonChange = (value) => {
    setOtherReason(value);
  };

  const reasonOptions = _.map(SPLIT_APPEAL_REASONS, (value) => ({
    label: value,
    value
  }));

  const issueOptions = () => requestIssues.map((issue) => ({
    id: issue.id.toString(),
    label:
      <>
        <span>{issue.description}</span><br />
        <span>Benefit Type: {BENEFIT_TYPES[issue.benefit_type]}</span><br />
        <span>Decision Date: {formatDateStr(issue.approx_decision_date)}</span>
        <br /><br />
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
        onChange={onReasonChange}
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
          value={otherReason}
          onChange={onOtherReasonChange}
          optional
        />
      )}
      <br />

      <h3>{COPY.SPLIT_APPEAL_CREATE_SELECT_ISSUES_TITLE}</h3>
      <CheckboxGroup
        vertical
        name="issues"
        label={COPY.SPLIT_APPEAL_CREATE_SELECT_ISSUES_TITLE}
        hideLabel
        values={selectedIssues}
        onChange={(val) => onIssueChange(val)}
        options={issueOptions()}
        styling={issueListStyling}
        strongLabel
      />
    </>
  );
};

SplitAppealView.propTypes = {
  serverIntake: PropTypes.object,
};

export default SplitAppealView;
