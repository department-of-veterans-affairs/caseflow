import React from 'react';
import { IntakeLayout } from '../IntakeLayout';
import { AddClaimantForm } from './AddClaimantForm';
import { AddClaimantButtons } from './AddClaimantButtons';

import { useAddClaimantForm } from './utils';
import { FormProvider } from 'react-hook-form';
import { useHistory } from 'react-router';

export const AddClaimantPage = () => {
  const { goBack } = useHistory();

  const methods = useAddClaimantForm();
  const {
    formState: { isValid },
    handleSubmit,
  } = methods;
  const onSubmit = (formData) => console.log('onSubmit', formData);
  const handleBack = () => goBack();

  return (
    <FormProvider {...methods}>
      <IntakeLayout
        buttons={
          <AddClaimantButtons
            onBack={handleBack}
            onSubmit={handleSubmit(onSubmit)}
            isValid={isValid}
          />
        }
      >
        <h1>Add Claimant</h1>
        <AddClaimantForm />
      </IntakeLayout>
    </FormProvider>
  );
};
