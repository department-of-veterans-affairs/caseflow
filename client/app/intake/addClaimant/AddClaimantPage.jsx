import React from 'react';
import { useHistory } from 'react-router';
import { FormProvider } from 'react-hook-form';

import AddClaimantForm from './AddClaimantForm';
import { IntakeLayout } from '../components/IntakeLayout';
import { AddClaimantButtons } from './AddClaimantButtons';

import { useAddClaimantForm } from './utils';
import { ADD_CLAIMANT_PAGE_DESCRIPTION } from 'app/../COPY';

export const AddClaimantPage = () => {
  const { goBack } = useHistory();
  const methods = useAddClaimantForm();
  const {
    formState: { isValid },
    handleSubmit,
  } = methods;
  const onSubmit = (formData) => {
    // Update this to...
    // Add claimant info to Redux
    // Probably handle submission of both claimant and remaining intake info (from Review step)
    return formData;
  };
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
        <p>{ADD_CLAIMANT_PAGE_DESCRIPTION}</p>
        <AddClaimantForm methods={methods} onSubmit={onSubmit} />
      </IntakeLayout>
    </FormProvider>
  );
};
