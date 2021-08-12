import React, { useEffect, useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { useHistory } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';
import { FormProvider } from 'react-hook-form';
import { camelCase } from 'lodash';
import { Redirect } from 'react-router-dom';
import {
  clearClaimant,
  clearPoa,
  editClaimantInformation,
} from '../reducers/addClaimantSlice';
import { AddClaimantConfirmationModal } from './AddClaimantConfirmationModal';
import { ClaimantForm } from './ClaimantForm';
import { IntakeLayout } from '../components/IntakeLayout';
import { AddClaimantButtons } from './AddClaimantButtons';
import { useClaimantForm, fetchAttorneys } from './utils';
import { submitReview } from '../actions/decisionReview';
import { FORM_TYPES, PAGE_PATHS, INTAKE_STATES } from '../constants';
import { getIntakeStatus } from '../selectors';

export const AddClaimantPage = ({ onAttorneySearch = fetchAttorneys, featureToggles }) => {
  const dispatch = useDispatch();
  const { goBack, push } = useHistory();

  const [confirmModal, setConfirmModal] = useState(false);
  const { claimant } = useSelector((state) => state.addClaimant);

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
  const intakeStatus = getIntakeStatus(useSelector((state) => state));

  // Redirect to Review page if review page data is not present (e.g. from a page reload)
  if (intakeStatus === INTAKE_STATES.STARTED && !intakeData.receiptDate) {
    return <Redirect to={PAGE_PATHS.REVIEW} />;
  }

  const methods = useClaimantForm({ defaultValues: claimant });
  const {
    formState: { isValid },
    handleSubmit,
    watch
  } = methods;

  const relationship = watch('relationship');
  const toggleConfirm = () => setConfirmModal((val) => !val);
  const handleConfirm = () => {
    const listedAttorney = claimant?.listedAttorney?.value;

    if (relationship === 'attorney' && listedAttorney !== 'not_listed') {
      intakeData.claimantType = 'attorney';
      intakeData.claimant = listedAttorney;
    } else {
      intakeData.unlistedClaimant = claimant;
    }
    dispatch(submitReview(intakeId, intakeData, selectedForm.formName));
    dispatch(clearClaimant());
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

  useEffect(() => {
    if (
      relationship &&
      claimant?.relationship &&
      claimant?.relationship !== relationship
    ) {
      dispatch(clearClaimant());
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
        <ClaimantForm
          onBack={handleBack}
          onSubmit={onSubmit}
          onAttorneySearch={onAttorneySearch}
          dateOfBirthField={featureToggles.dateOfBirthField}
        />
        {confirmModal && (
          <AddClaimantConfirmationModal
            onCancel={toggleConfirm}
            onConfirm={handleConfirm}
            claimant={claimant}
          />
        )}
      </IntakeLayout>
    </FormProvider>
  );
};
AddClaimantPage.propTypes = {
  featureToggles: PropTypes.object,
  onAttorneySearch: PropTypes.func,
};
