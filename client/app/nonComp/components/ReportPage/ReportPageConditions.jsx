import React from 'react';
import { useFormContext, useFieldArray } from 'react-hook-form';

import { ConditionContainer } from './ConditionContainer';
import { personnelSchema } from './Conditions/Personnel';
import Button from 'app/components/Button';

import * as yup from 'yup';
import { daysWaitingSchema } from './Conditions/DaysWaiting';
import { decisionReviewTypeSchema } from './Conditions/DecisionReviewType';
import { facilitySchema } from './Conditions/Facility';
import { issueDispositionSchema } from './Conditions/IssueDisposition';
import * as ERRORS from 'constants/REPORT_PAGE_VALIDATION_ERRORS';
import { issueTypeSchema } from './Conditions/IssueType';

const conditionOptionSchemas = {
  daysWaiting: daysWaitingSchema,
  decisionReviewType: decisionReviewTypeSchema,
  facility: facilitySchema,
  issueDisposition: issueDispositionSchema,
  issueType: issueTypeSchema,
  personnel: personnelSchema
};

export const conditionsSchema = yup.array().of(
  yup.lazy((value) => {
    return yup.object(
      { condition: yup.string().typeError(ERRORS.MISSING_CONDITION).
        transform((curr, orig) => (orig === '' ? null : curr)).
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
      <hr style={{ margin: '50px 0' }} />
      {/* Update margin depending on the presence of controlledField elements */}
      <h2 style={controlledFields.length ? { margin: '0' } : null}>Conditions</h2>
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
