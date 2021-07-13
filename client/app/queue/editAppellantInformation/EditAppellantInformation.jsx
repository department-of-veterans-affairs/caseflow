import React from 'react';
import { FormProvider } from 'react-hook-form';

import { ClaimantForm as EditClaimantForm } from '../../intake/addClaimant/ClaimantForm';
import { useClaimantForm } from '../../intake/addClaimant/utils';
import Button from '../../components/Button';
import { updateAppellantInformation } from './editAppellantInformationSlice';
import { useDispatch } from 'react-redux';
import { EDIT_CLAIMANT_PAGE_DESCRIPTION } from 'app/../COPY';
import { IntakeLayout } from '../../intake/components/IntakeLayout';

const EditAppellantInformation = () => {
  const dispatch = useDispatch();
  // CASEFLOW-1921: Pass in the existing appellant information as default values

  const methods = useClaimantForm({ defaultValues: {} });

  const {
    handleSubmit,
  } = methods;

  const handleUpdate = (formData) => {
    // CASEFLOW-1921: Get the actual appellant ID
    const id = 1;

    dispatch(updateAppellantInformation({ formData, id }));
  };

  const editAppellantHeader = 'Edit Appellant Information';
  const editAppellantDescription = EDIT_CLAIMANT_PAGE_DESCRIPTION;

  return <div>
    <FormProvider {...methods}>
      <IntakeLayout>
        <EditClaimantForm editAppellantHeader={editAppellantHeader} editAppellantDescription={editAppellantDescription} />
        <Button onClick={handleSubmit(handleUpdate)}>Submit</Button>
      </IntakeLayout>
    </FormProvider>
  </div>;
};

export default EditAppellantInformation;
