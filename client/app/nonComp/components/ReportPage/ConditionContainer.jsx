import React, { useMemo } from 'react';
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

export const ConditionContainer = ({ control, index, remove, field }) => {
  // this can't easily be extracted to somewhere else without breaking the form
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

  const { watch, register } = useFormContext();
  const conds = watch('conditions');

  let selectedOptions = conds.map((cond) => cond.condition).filter((cond) => cond !== null && cond !== field.condition);

  // personnel and facility are mutually exclusive
  if (selectedOptions.includes('facility')) {
    selectedOptions = selectedOptions.concat('personnel');
  } else if (selectedOptions.includes('personnel')) {
    selectedOptions = selectedOptions.concat('facility');
  }

  const filteredOptions = variableOptions.filter((option) =>
    !selectedOptions.some((selectedOption) => option.value === selectedOption));

  const name = `conditions.${index}`;

  const conditionsLength = useWatch({ name: 'conditions' }).length;
  const shouldShowAnd = (conditionsLength > 1) && (index !== (conditionsLength - 1));
  const selectedConditionValue = useWatch({ control, name: `${name}.condition` });
  const selectedVariableOption = variableOptions.find((opt) => opt.value === selectedConditionValue);

  const hasMiddleContent = selectedConditionValue && selectedConditionValue !== 'daysWaiting';
  const middleContentClassName = hasMiddleContent ?
    'report-page-variable-content' :
    'report-page-variable-content-wider';

  const conditionContent = useMemo(() => {

    if (!selectedConditionValue || !selectedVariableOption) {
      return <div></div>;
    }

    if (selectedVariableOption.component) {
      const ConditionContent = selectedVariableOption.component;

      return <ConditionContent {...{ control, register, name, field }} />;
    }
  }, [control, name, register, selectedConditionValue, variableOptions]);

  return <div className="report-page-segment">
    <div className="cf-app-segment cf-app-segment--alt report-page-variable-condition" >
      <div className="report-page-variable-select">
        <ConditionDropdown {...{ control, filteredOptions, name, field }} />
      </div>
      {hasMiddleContent ? <div className="report-page-middle-content">including</div> : null}
      <div className={middleContentClassName}>
        {conditionContent}
      </div>
    </div>
    <Link onClick={() => remove(index)}>Remove condition</Link>
    {shouldShowAnd ? <div className="report-page-condition-and">AND</div> : null}
  </div>;
};

ConditionContainer.propTypes = {
  control: PropTypes.object,
  field: PropTypes.object,
  index: PropTypes.number,
  remove: PropTypes.func,
};
