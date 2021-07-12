import React from 'react';
import { FormProvider } from 'react-hook-form';
import { useDispatch } from 'react-redux';

import { AddClaimantForm } from '../../intake/addClaimant/AddClaimantForm';
import { useAddClaimantForm } from '../../intake/addClaimant/utils';
import { updateAppellantInformation } from './actions';
import Button from '../../components/Button';

const EditAppellantInformation = () => {
  const dispatch = useDispatch();

  // TODO: Pass in the existing appellant information as default values
  const methods = useAddClaimantForm({ defaultValues: {} });
  const {
    handleSubmit,
  } = methods;

  const handleUpdate = (values) => {
    // TODO: Get appellant ID from existing appeal's appellant
    // For now, we'll just pass in a random ID for WIP
    dispatch(updateAppellantInformation(values, 1));
  };

  return <div>
    <h1>Edit Appellant Information</h1>
    <FormProvider {...methods}>
      <AddClaimantForm />
      <Button onClick={handleSubmit(handleUpdate)}>Submit</Button>
    </FormProvider>
  </div>;
};

export default EditAppellantInformation;
