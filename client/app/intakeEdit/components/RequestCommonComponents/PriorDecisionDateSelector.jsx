import React from 'react';
import DateSelector from 'app/components/DateSelector';
import { useFormContext } from 'react-hook-form';

const PriorDecisionDateSelector = () => {
  const { register } = useFormContext();

  return <DateSelector
    label="Prior decision date"
    name="decisionDate"
    inputRef={register}
    type="date" />;
};

export default PriorDecisionDateSelector;
