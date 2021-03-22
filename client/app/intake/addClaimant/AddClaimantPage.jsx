import React, { useEffect, useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { useHistory } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';
import { FormProvider } from 'react-hook-form';
import { camelCase } from 'lodash';

import {
  clearClaimant,
  clearPoa,
  editClaimantInformation,
} from '../reducers/addClaimantSlice';
import { AddClaimantConfirmationModal } from './AddClaimantConfirmationModal';
import { AddClaimantForm } from './AddClaimantForm';
import { IntakeLayout } from '../components/IntakeLayout';
import { AddClaimantButtons } from './AddClaimantButtons';
import { useAddClaimantForm, fetchAttorneys } from './utils';
// eslint-disable-next-line no-unused-vars
import { submitReview } from '../actions/decisionReview';
import { FORM_TYPES } from '../constants';

export const AddClaimantPage = ({ onAttorneySearch = fetchAttorneys }) => {
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
    intakeData.claimant = claimant;

    dispatch(submitReview(intakeId, intakeData, selectedForm.formName));
    push('/add_issues');
  };

  const onSubmit = (formData) => {
    if (formData.firstName) {
      formData.partyType = 'individual';
    }

    dispatch(editClaimantInformation({ formData }));

    if (formData.poaForm === 'true') {
      push('/add_power_of_attorney');
    } else {
      // In case user has come back to this page and changed value on poaForm
      dispatch(clearPoa());

      // Regardless, show confirmation modal
      toggleConfirm();
    }
  };

  const handleBack = () => goBack();

  const methods = useAddClaimantForm({ defaultValues: claimant });
  const {
    formState: { isValid },
    handleSubmit,
    watch,
  } = methods;

  const relationship = watch('relationship');

  useEffect(() => {
    if (
      relationship &&
      claimant?.relationship &&
      claimant?.relationship !== relationship
    ) {
      dispatch(clearClaimant());
      // reset();
    }
  }, [relationship, claimant]);

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
        <AddClaimantForm
          onBack={handleBack}
          onSubmit={onSubmit}
          onAttorneySearch={onAttorneySearch}
        />
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
AddClaimantPage.propTypes = {
  onAttorneySearch: PropTypes.func,
};
