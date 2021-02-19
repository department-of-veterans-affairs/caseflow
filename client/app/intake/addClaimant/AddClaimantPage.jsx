import React, { useState } from 'react';
import { useHistory } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';

import { editClaimantInformation } from '../reducers/addClaimantSlice';
import { AddClaimantConfirmationModal } from './AddClaimantConfirmationModal';
import { AddClaimantForm } from './AddClaimantForm';
import { IntakeLayout } from '../components/IntakeLayout';
import { AddClaimantButtons } from './AddClaimantButtons';
import { FormProvider } from 'react-hook-form';
import { useAddClaimantForm } from './utils';

export const AddClaimantPage = () => {
  const dispatch = useDispatch();
  const { goBack, push } = useHistory();

  const [confirmModal, setConfirmModal] = useState(false);
  const { claimant, poa } = useSelector((state) => state.addClaimant);

  const toggleConfirm = () => setConfirmModal((val) => !val);
  const handleConfirm = () => {
    push('/add_issues');
  };

  const onSubmit = (formData) => {
    // Add stuff to redux store
    dispatch(editClaimantInformation({ formData }));

    if (formData.vaForm === 'true') {
      push('/add_power_of_attorney');
    } else {
      toggleConfirm();
    }
  };

  const handleBack = () => goBack();

  const methods = useAddClaimantForm();
  const {
    formState: { isValid },
    handleSubmit,
  } = methods;

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
        <AddClaimantForm onBack={handleBack} onSubmit={onSubmit} />
        {confirmModal && (
          <AddClaimantConfirmationModal
            onCancel={toggleConfirm}
            onConfirm={handleConfirm}
            claimant={claimant}
            poa={poa}
          />
        )}
      </IntakeLayout>
    </FormProvider>
  );
};
