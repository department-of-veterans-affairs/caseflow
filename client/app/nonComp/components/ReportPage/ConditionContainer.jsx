import React from 'react';
import { useWatch, useFormContext } from 'react-hook-form';
import { ConditionDropdown } from './ConditionDropdown';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { DaysWaiting } from './Conditions/DaysWaiting';
import { DecisionReviewType } from './Conditions/DecisionReviewType';
import { IssueType } from './Conditions/IssueType';
import { IssueDisposition } from './Conditions/IssueDisposition';
import { Facility } from './Conditions/Facility';
import { Personnel } from './Conditions/Personnel';
import PropTypes from 'prop-types';

export const ConditionContainer = ({ control, index, remove }) => {

  const { watch, register } = useFormContext();

  const variableOptions = [
    { label: 'Days Waiting',
      value: 'daysWaiting',
      component: DaysWaiting },
    { label: 'Decision Review Type',
      value: 'decisionReviewType',
      component: DecisionReviewType },
    { label: 'Issue Type',
      value: 'issueType',
      component: IssueType },
    { label: 'Issue Disposition',
      value: 'issueDisposition',
      component: IssueDisposition },
    { label: 'Personnel',
      value: 'personnel',
      component: Personnel },
    { label: 'Facility',
      value: 'facility',
      component: Facility },
  ];

  const determineOptions = () => {
    let conds = watch('conditions');
    let selectedOptions = conds.map((cond) => cond.condition).filter((cond) => cond !== null);

    // personnel and facility are mutually exclusive
    if (selectedOptions.includes('facility')) {
      selectedOptions = selectedOptions.concat('personnel');
    } else if (selectedOptions.includes('personnel')) {
      selectedOptions = selectedOptions.concat('facility');
    }

    return variableOptions.filter((option) =>
      !selectedOptions.some((selectedOption) => option.value === selectedOption));
  };

  const name = `conditions.${index}`;

  const conditionsLength = useWatch({ name: 'conditions' }).length;
  const shouldShowAnd = (conditionsLength > 1) && (index !== (conditionsLength - 1));

  const selectedConditionValue = useWatch({ control, name: `${name}.condition` });

  const getConditionContent = () => {
    const selectedVariableOption = variableOptions.find((opt) => opt.value === selectedConditionValue);

    if (!selectedConditionValue || !selectedVariableOption) {
      return <div></div>;
    }

    if (selectedVariableOption.component) {
      const ConditionContent = selectedVariableOption.component;

      return <ConditionContent {...{ control, register, name }} />;
    }
  };

  return <div className="report-page-segment">
    <div className="cf-app-segment cf-app-segment--alt report-page-variable-condition" >
      <div className="report-page-variable-select">
        <ConditionDropdown {...{ control, determineOptions, name }} />
      </div>
      <div className="report-page-variable-content">{selectedConditionValue ? getConditionContent() : null} </div>
    </div>
    <Link onClick={() => remove(index)}>Remove condition</Link>
    {shouldShowAnd ? <div className="report-page-condition-and">AND</div> : null}
  </div>;
};

ConditionContainer.propTypes = {
  control: PropTypes.object,
  index: PropTypes.number,
  remove: PropTypes.func
};
