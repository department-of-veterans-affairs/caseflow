import React from 'react';
import { useFormContext, useFieldArray } from 'react-hook-form';
import * as yup from 'yup';

import { ConditionContainer } from './ConditionContainer';
import { personnelSchema } from './Conditions/Personnel';
import Button from 'app/components/Button';

const conditionOptionSchemas = {
  daysWaiting: yup.object(),
  decisionReviewType: yup.object(),
  facility: yup.object(),
  issueDisposition: yup.object(),
  issueType: yup.object(),
  personnel: personnelSchema
};

export const conditionsSchema = yup.array().of(
  yup.lazy((value) => {
    return yup.object(
      { condition: yup.string().typeError('Error').
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
        return <ConditionContainer key={field.id} {... { control, field, index, remove }} />;
      })}
      <Button
        disabled={watchFieldArray.length >= 5}
        onClick={() => append({ condition: '', options: {} })}>
      Add Condition</Button>
    </div>
  );
};
