import React, { useMemo, useState } from 'react';
import { useHistory } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';
import { FormProvider } from 'react-hook-form';

import { editClaimantInformation } from '../reducers/addClaimantSlice';
import { AddClaimantConfirmationModal } from './AddClaimantConfirmationModal';
import { AddClaimantForm } from './AddClaimantForm';
import { IntakeLayout } from '../components/IntakeLayout';
import { AddClaimantButtons } from './AddClaimantButtons';
import { useAddClaimantForm } from './utils';
// eslint-disable-next-line no-unused-vars
import { submitReview } from '../actions/decisionReview';
import { FORM_TYPES } from '../constants';
import { camelCase } from 'lodash';

export const AddClaimantPage = () => {
  const dispatch = useDispatch();
  const { goBack, push } = useHistory();

  const [confirmModal, setConfirmModal] = useState(false);
  const { claimant, poa } = useSelector((state) => state.addClaimant);

  /* eslint-disable no-unused-vars */
  // This code will likely be needed in submission (see handleConfirm)
  // Remove eslint-disable once used
  const { formType, id: intakeId } = useSelector((state) => state.intake);
  const intakeForms = useSelector(
    ({ higherLevelReview, supplementalClaim, appeal }) => ({
      appeal,
      higherLevelReview,
      supplementalClaim,
    })
  );

  const selectedForm = useMemo(() => {
    return Object.values(FORM_TYPES).find((item) => item.key === formType);
  }, [formType]);
  const intakeData = useMemo(() => {
    return selectedForm ? intakeForms[camelCase(formType)] : null;
  }, [intakeForms, formType, selectedForm]);
  /* eslint-enable no-unused-vars */

  const toggleConfirm = () => setConfirmModal((val) => !val);
  const handleConfirm = () => {
    // TODO - trigger action to submit data to backend
    // dispatch(submitReview(intakeId, intakeData, selectedForm.formName));

    // Redirect to next step (likely needs conditional on review type)
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

  const methods = useAddClaimantForm({ defaultValues: claimant });
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
