import React from 'react';
import { FormProvider } from 'react-hook-form';

import { AddClaimantForm as EditClaimantForm } from '../../intake/addClaimant/AddClaimantForm';
import { useAddClaimantForm } from '../../intake/addClaimant/utils';
import Button from '../../components/Button';
import { updateAppellantInformation } from './editAppellantInformationSlice';
import { useDispatch } from 'react-redux';

const EditAppellantInformation = () => {
  const dispatch = useDispatch();
  // CASEFLOW-1921: Pass in the existing appellant information as default values
  const methods = useAddClaimantForm({ defaultValues: {} });
  const {
    handleSubmit,
  } = methods;

  const handleUpdate = (formData) => {
    // CASEFLOW-1921: Get the actual appellant ID
    const id = 1;

    dispatch(updateAppellantInformation({ formData, id }));
  };

  return <div>
    <h1>Edit Appellant Information</h1>
    <FormProvider {...methods}>
      <EditClaimantForm />
      <Button onClick={handleSubmit(handleUpdate)}>Submit</Button>
    </FormProvider>
  </div>;
};

export default EditAppellantInformation;
