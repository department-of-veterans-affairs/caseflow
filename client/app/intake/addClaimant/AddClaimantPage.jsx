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

  // Redirect to Intake homepage if formType is null
  const intakeIsCancelled = useMemo(() => !formType, [formType]);

  // Redirect to Review page if review page data is not present (e.g. from a page reload)
  if (intakeStatus === INTAKE_STATES.STARTED && !intakeData.receiptDate) {
    return <Redirect to={PAGE_PATHS.REVIEW} />;
  }

  const methods = useClaimantForm({ defaultValues: claimant, selectedForm });
  const {
    formState: { isValid },
    handleSubmit,
    watch,
    reset
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

    // Database schema will not allow nulls for state, but it's possibly an optional field for individuals now.
    if (!formData.state) {
      formData.state = '';
    }

    // Remove dashes and spaces from SSN before submitting it to the server
    if (formData.ssn) {
      formData.ssn = formData.ssn.replace(/-|\s/g, '');
    }

    // Adjust the claimant type for Healthcare Providers so it will be constantized properly
    if (formData.relationship === 'healthcare_provider') {
      intakeData.claimantType = 'healthcare_provider';
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
      reset({ partyType: null, relationship });
    }
  }, [relationship, claimant]);

  return (
    <FormProvider {...methods}>
      {intakeIsCancelled && <Redirect to={PAGE_PATHS.BEGIN} />}
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
          dateOfBirthFieldToggle={featureToggles?.dateOfBirthField || false}
          formType={formType}
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
