import React from 'react';
import { useFormContext, useFieldArray } from 'react-hook-form';
import { ConditionContainer } from './ConditionContainer';
import Button from 'app/components/Button';

export const ReportPageConditions = () => {
  const { control, watch } = useFormContext();
  const { fields, append, remove } = useFieldArray({
    control,
    name: 'conditions',
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
        return <ConditionContainer key={field.id} {... { control, index, remove }} />;
      })}
      <Button
        disabled={watchFieldArray.length >= 5}
        onClick={() => append({ condition: '' })}>
      Add Condition</Button>
    </div>
  );
};
