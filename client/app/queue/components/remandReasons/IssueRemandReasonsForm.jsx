import React from 'react';
import PropTypes from 'prop-types';
import { flexColumn, flexContainer } from './constants';
import CheckboxGroup from '../../../components/CheckboxGroup';
import { LEGACY_REMAND_REASONS } from '../../constants';
import { IssueRemandReasonCheckbox } from './IssueRemandReasonCheckbox';

export const LegacyCheckboxGroup = () => {
  const getCheckbox = (option, onChange) => <IssueRemandReasonCheckbox option={option} onChange={onChange} isLegacyAppeal />;
  const checkboxGroupProps = {
    onChange: (val) => console.log('checkbox onChange', val),
    getCheckbox,
    // values: this.state
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

export const IssueRemandReasonsForm = ({ isLegacyAppeal = false, issue }) => {

  return isLegacyAppeal ? <LegacyCheckboxGroup /> : <div>Moo</div>;
};
IssueRemandReasonsForm.propTypes = {
  isLegacyAppeal: PropTypes.bool,
  issue: PropTypes.object
};
