import React from 'react';
import { useFormContext, useFieldArray } from 'react-hook-form';
import { ConditionContainer } from './ConditionContainer';
import Button from 'app/components/Button';

import * as yup from 'yup';
import { daysWaitingSchema } from './Conditions/DaysWaiting';
import * as ERRORS from 'constants/REPORT_PAGE_VALIDATION_ERRORS';

const conditionOptionSchemas = {
  daysWaiting: daysWaitingSchema,
  decisionReviewType: yup.object(),
  facility: yup.object(),
  issueDisposition: yup.object(),
  issueType: yup.object(),
  personnel: yup.object()
};

export const conditionsSchema = yup.array().of(
  yup.lazy((value) => {
    return yup.object(
      { condition: yup.string().typeError(ERRORS.MISSING_CONDITION).
        oneOf(['daysWaiting', 'decisionReviewType', 'facility', 'issueDisposition', 'issueType', 'personnel']).
        required(),
      options: conditionOptionSchemas[value.condition]
      });
  })
);

export const ReportPageConditions = () => {
  const { control, watch } = useFormContext();
  const { fields, append, remove } = useFieldArray({
    control,
    name: 'conditions',
    defaultValues: [{ condition: '', options: {} }]
  });

  const watchFieldArray = watch('conditions');
  const controlledFields = fields.map((field, index) => {
    return {
      ...field,
      ...watchFieldArray[index]
    };
  });

  return (
    <div>
      <hr style={{ marginTop: '50px', marginBottom: '50px' }} />
      <h2>Conditions</h2>
      {controlledFields.map((field, index) => {
        return <ConditionContainer key={field.id} {... { control, index, remove, field }} />;
      })}
      <Button
        disabled={watchFieldArray.length >= 5}
        onClick={() => append({ condition: '', options: {} })}>
      Add Condition</Button>
    </div>
  );
};
