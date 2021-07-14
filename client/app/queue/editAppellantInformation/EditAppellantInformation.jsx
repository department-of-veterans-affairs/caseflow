import React from 'react';
import { FormProvider } from 'react-hook-form';
import { useHistory } from 'react-router';

import { ClaimantForm as EditClaimantForm } from '../../intake/addClaimant/ClaimantForm';
import { useClaimantForm } from '../../intake/addClaimant/utils';
import Button from '../../components/Button';
import { updateAppellantInformation } from './editAppellantInformationSlice';
import { useDispatch } from 'react-redux';
import { EDIT_CLAIMANT_PAGE_DESCRIPTION } from 'app/../COPY';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

const EditAppellantInformation = () => {
  const dispatch = useDispatch();
  // CASEFLOW-1921: Pass in the existing appellant information as default values

  const methods = useClaimantForm({ defaultValues: {} });
  const { goBack } = useHistory();

  const {
    handleSubmit,
  } = methods;

  const handleUpdate = (formData) => {
    // CASEFLOW-1921: Get the actual appellant ID
    const id = 1;

    dispatch(updateAppellantInformation({ formData, id }));
  };

  const handleBack = () => goBack();

  const editAppellantHeader = 'Edit Appellant Information';
  const editAppellantDescription = EDIT_CLAIMANT_PAGE_DESCRIPTION;

  return <div>
    <FormProvider {...methods}>
      <AppSegment filledBackground>
        <EditClaimantForm
          editAppellantHeader={editAppellantHeader}
          editAppellantDescription={editAppellantDescription}
        />
      </AppSegment>
      <Button
        onClick={handleSubmit(handleUpdate)}
        classNames={['cf-right-side']}
      >
        Save
      </Button>
      <Button
        onClick={handleBack}
        classNames={['cf-right-side', 'usa-button-secondary']}
        styling={{ style: { marginRight: '1em' } }}
      >
        Cancel
      </Button>
    </FormProvider>
  </div>;
};

export default EditAppellantInformation;
