import React from 'react';
import PropTypes from 'prop-types';
import { IntakeLayout } from '../IntakeLayout';
import { AddClaimantForm } from './AddClaimantForm';
import { AddClaimantButtons } from './AddClaimantButtons';

import { useAddClaimantForm } from './utils';
import { FormProvider } from 'react-hook-form';

export const AddClaimantPage = () => {
  const methods = useAddClaimantForm();
  const {
    formState: { isValid },
    handleSubmit,
  } = methods;
  const onSubmit = (formData) => console.log('onSubmit', formData);

  return (
    <FormProvider {...methods}>
      <IntakeLayout
        buttons={
          <AddClaimantButtons
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
