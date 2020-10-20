import React, { useEffect, useMemo, useState } from 'react';
import PropTypes from 'prop-types';

import { css } from 'glamor';

import CheckboxGroup from 'app/components/CheckboxGroup';
import {
  LEGACY_REMAND_REASONS,
  REMAND_REASONS,
  fullWidth,
  boldText,
  redText,
} from 'app/queue/constants';
import BENEFIT_TYPES from 'constants/BENEFIT_TYPES';
import { IssueRemandReasonCheckbox } from './IssueRemandReasonCheckbox';
import {
  errorNoTopMargin,
  flexColumn,
  flexContainer,
  smallBottomMargin,
} from './constants';
import {
  getIssueDiagnosticCodeLabel,
  getIssueProgramDescription,
  getIssueTypeDescription,
} from '../../utils';
import { formatDateStr } from '../../../util/DateUtil';

export const LegacyCheckboxGroup = ({ onChange, highlight }) => {
  const getCheckbox = (option, checkboxChange) => (
    <IssueRemandReasonCheckbox
      option={option}
      onChange={checkboxChange}
      isLegacyAppeal
      highlight={highlight}
    />
  );
  const checkboxGroupProps = {
    onChange,
    getCheckbox,
  };

  return (
    <div {...flexContainer}>
      <div {...flexColumn}>
        <CheckboxGroup
          label={<h3>Medical examination and opinion</h3>}
          name="med-exam"
          options={LEGACY_REMAND_REASONS.medicalExam}
          {...checkboxGroupProps}
        />
        <CheckboxGroup
          label={<h3>Duty to assist records request</h3>}
          name="duty-to-assist"
          options={LEGACY_REMAND_REASONS.dutyToAssistRecordsRequest}
          {...checkboxGroupProps}
        />
      </div>
      <div {...flexColumn}>
        <CheckboxGroup
          label={<h3>Duty to notify</h3>}
          name="duty-to-notify"
          options={LEGACY_REMAND_REASONS.dutyToNotify}
          {...checkboxGroupProps}
        />
        <CheckboxGroup
          label={<h3>Due process</h3>}
          name="due-process"
          options={LEGACY_REMAND_REASONS.dueProcess}
          {...checkboxGroupProps}
        />
      </div>
    </div>
  );
};
LegacyCheckboxGroup.propTypes = {
  highlight: PropTypes.bool,
  onChange: PropTypes.func,
};

export const AmaCheckboxGroup = ({ onChange, highlight }) => {
  const getCheckbox = (option, checkboxChange) => (
    <IssueRemandReasonCheckbox
      option={option}
      onChange={checkboxChange}
      isLegacyAppeal
      highlight={highlight}
    />
  );
  const checkboxGroupProps = {
    onChange,
    getCheckbox,
  };

  return (
    <div {...flexContainer}>
      <div {...flexColumn}>
        <CheckboxGroup
          label={<h3>Duty to notify</h3>}
          name="duty-to-notify"
          options={REMAND_REASONS.dutyToNotify}
          {...checkboxGroupProps}
        />
        <CheckboxGroup
          label={<h3>Duty to assist</h3>}
          name="duty-to-assist"
          options={REMAND_REASONS.dutyToAssist}
          {...checkboxGroupProps}
        />
      </div>
      <div {...flexColumn}>
        <CheckboxGroup
          label={<h3>Medical examination</h3>}
          name="medical-exam"
          options={REMAND_REASONS.medicalExam}
          {...checkboxGroupProps}
        />
        <br />
        <CheckboxGroup
          label={<h3>Due Process</h3>}
          name="due-process"
          options={REMAND_REASONS.dueProcess}
          {...checkboxGroupProps}
        />
      </div>
    </div>
  );
};
AmaCheckboxGroup.propTypes = {
  highlight: PropTypes.bool,
  onChange: PropTypes.func,
};

export const IssueRemandReasonsForm = ({
  certificationDate,
  isLegacyAppeal = false,
  issue,
  issueNumber = 1,
  issueTotal = 1,
  highlight,
  onChange,
}) => {
  const [fields, setFields] = useState({});

  // eslint-disable-next-line camelcase
  const handleChange = ({ code, checked, post_aoj }) => {
    setFields({
      ...fields,
      [code]: { code, checked, post_aoj },
    });
  };
  const checkboxGroupProps = { onChange: handleChange, highlight };

  const selected = useMemo(
    () => Object.values(fields).filter((item) => item.checked),
    [fields]
  );

  useEffect(() => {
    onChange?.(selected);
  }, [selected]);

  return (
    <div key={`remand-reasons-${String(issue.id)}`}>
      <h2 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>
        Issue {issueNumber} {issueTotal > 1 ? ` of ${issueTotal}` : ''}
      </h2>
      <div {...smallBottomMargin}>
        {isLegacyAppeal ?
          `Program: ${getIssueProgramDescription(issue)}` :
          `Benefit type: ${BENEFIT_TYPES[issue.benefit_type]}`}
      </div>
      {!isLegacyAppeal && (
        <div {...smallBottomMargin}>Issue description: {issue.description}</div>
      )}
      {isLegacyAppeal && (
        <React.Fragment>
          <div {...smallBottomMargin}>
            Issue: {getIssueTypeDescription(issue)}
          </div>
          <div {...smallBottomMargin}>
            Code:{' '}
            {getIssueDiagnosticCodeLabel(issue.codes[issue.codes.length - 1])}
          </div>
          <div
            {...smallBottomMargin}
            ref={(node) => (this.elTopOfWarning = node)}
          >
            Certified: {formatDateStr(certificationDate)}
          </div>
          <div {...smallBottomMargin}>Note: {issue.note}</div>
        </React.Fragment>
      )}
      {highlight && !selected.length && (
        <div
          className="usa-input-error"
          {...css(redText, boldText, errorNoTopMargin)}
        >
          Choose at least one
        </div>
      )}
      {isLegacyAppeal ? (
        <LegacyCheckboxGroup {...checkboxGroupProps} />
      ) : (
        <AmaCheckboxGroup {...checkboxGroupProps} />
      )}
    </div>
  );
};
IssueRemandReasonsForm.propTypes = {
  certificationDate: PropTypes.string,
  isLegacyAppeal: PropTypes.bool,
  issue: PropTypes.object.isRequired,
  issueNumber: PropTypes.number,
  issueTotal: PropTypes.number,
  highlight: PropTypes.bool,
  onChange: PropTypes.func,
};
