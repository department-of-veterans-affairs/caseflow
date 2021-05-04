import React, { useCallback, useMemo, useState } from 'react';
import { FormProvider, Controller } from 'react-hook-form';
import { Redirect } from 'react-router-dom';
import { useAddPoaForm } from './utils';
import { ADD_CLAIMANT_POA_PAGE_DESCRIPTION, ERROR_EMAIL_INVALID_FORMAT } from 'app/../COPY';
import { IntakeLayout } from '../components/IntakeLayout';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { AddClaimantButtons } from '../addClaimant/AddClaimantButtons';
import styled from 'styled-components';
import { useHistory } from 'react-router';
import { camelCase, debounce } from 'lodash';
import ApiUtil from '../../util/ApiUtil';
import RadioField from 'app/components/RadioField';
import Address from 'app/queue/components/Address';
import AddressForm from 'app/components/AddressForm';
import TextField from 'app/components/TextField';
import { useDispatch, useSelector } from 'react-redux';
import { editPoaInformation, clearPoa, clearClaimant } from 'app/intake/reducers/addClaimantSlice';
import { AddClaimantConfirmationModal } from '../addClaimant/AddClaimantConfirmationModal';
import { formatAddress } from '../addClaimant/utils';
import { FORM_TYPES, PAGE_PATHS, INTAKE_STATES } from '../constants';
import { getIntakeStatus } from '../selectors';
import { submitReview } from '../actions/decisionReview';

const partyTypeOpts = [
  { displayText: 'Organization', value: 'organization' },
  { displayText: 'Individual', value: 'individual' },
];

const fetchAttorneys = async (search = '') => {
  const res = await ApiUtil.get('/intake/attorneys', {
    query: { query: search },
  });
  return res?.body;
};

const getAttorneyClaimantOpts = async (search = '', asyncFn) => {
  // Enforce minimum search length (we'll simply return empty array rather than throw error)
  if (search.length < 3) {
    return [];
  }

  const res = await asyncFn(search);
  const options = res.map((item) => ({
    label: item.name,
    value: item.participant_id,
    address: formatAddress(item.address),
  }));

  options.push({ label: 'Name not listed', value: 'not_listed' });

  return options;
};

const filterOption = () => true;

export const AddPoaPage = () => {
  const { goBack, push } = useHistory();
  const dispatch = useDispatch();

  const [confirmModal, setConfirmModal] = useState(false);
  const { claimant, poa } = useSelector((state) => state.addClaimant);

  const methods = useAddPoaForm({ defaultValues: poa });
  const {
    control,
    register,
    watch,
    formState: { isValid, errors },
    handleSubmit
  } = methods;

  /* eslint-disable no-unused-vars */
  // This code will likely be needed in submission (see handleConfirm)
  // Remove eslint-disable once used
  const emailValidationError = errors.emailAddress && ERROR_EMAIL_INVALID_FORMAT;

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

  // Redirect to page where data needs to be re-populated (e.g. from a page reload)
  if (intakeStatus === INTAKE_STATES.STARTED) {
    if (!intakeData.receiptDate) {
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    } else if (!claimant?.relationship) {
      return <Redirect to={PAGE_PATHS.ADD_CLAIMANT} />;
    }
  }

  const toggleConfirm = () => setConfirmModal((val) => !val);
  const handleConfirm = () => {
    intakeData.unlistedClaimant = claimant;
    intakeData.poa = poa;

    dispatch(submitReview(intakeId, intakeData, selectedForm.formName));
    dispatch(clearPoa());
    dispatch(clearClaimant());
    push('/add_issues');
  };

  const onSubmit = (formData) => {
    // Add to Redux store
    dispatch(editPoaInformation({ formData }));

    toggleConfirm();
  };
  const handleBack = () => goBack();

  const watchPartyType = watch('partyType');
  const showIndividualNameFields = watchPartyType === 'individual';

  const watchListedAttorney = watch('listedAttorney');
  const attorneyNotListed = watchListedAttorney?.value === 'not_listed';
  const showPartyType = attorneyNotListed;
  const showAdditionalFields = watchPartyType && showPartyType;

  const asyncFn = useCallback(
    debounce((search, callback) => {
      getAttorneyClaimantOpts(search, fetchAttorneys).then((res) =>
        callback(res)
      );
    }, 250),
    [fetchAttorneys]
  );

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
        <h1>Add Claimant's POA</h1>
        <p>{ADD_CLAIMANT_POA_PAGE_DESCRIPTION}</p>

        <form onSubmit={handleSubmit(onSubmit)}>
          <h2>Representative</h2>
          <Controller
            control={control}
            name="listedAttorney"
            defaultValue={null}
            render={({ ...rest }) => (
              <FieldDiv>
                <SearchableDropdown
                  {...rest}
                  label="Representative's name"
                  filterOption={filterOption}
                  async={asyncFn}
                  defaultOptions
                  debounce={250}
                  strongLabel
                  isClearable
                  placeholder="Type to search..."
                />
              </FieldDiv>
            )}
          />

          {watchListedAttorney?.address && (
            <div>
              <ClaimantAddress>
                <strong>Representative's address</strong>
              </ClaimantAddress>
              <br />
              <Address address={watchListedAttorney?.address} />
            </div>
          )}

          {showPartyType && (
            <RadioField
              name="partyType"
              label="Is the representative an organization or individual?"
              inputRef={register}
              strongLabel
              vertical
              options={partyTypeOpts}
            />
          )}

          <br />
          {showIndividualNameFields && (
            <>
              <FieldDiv>
                <TextField
                  name="firstName"
                  label="First name"
                  inputRef={register}
                  strongLabel
                />
              </FieldDiv>
              <FieldDiv>
                <TextField
                  name="middleName"
                  label="Middle name/initial"
                  inputRef={register}
                  optional
                  strongLabel
                />
              </FieldDiv>
              <FieldDiv>
                <TextField
                  name="lastName"
                  label="Last name"
                  inputRef={register}
                  optional
                  strongLabel
                />
              </FieldDiv>
              <Suffix>
                <TextField
                  name="suffix"
                  label="Suffix"
                  inputRef={register}
                  optional
                  strongLabel
                />
              </Suffix>
            </>
          )}

          {showPartyType && watchPartyType === 'organization' && (
            <TextField
              name="name"
              label="Organization name"
              inputRef={register}
              strongLabel
            />
          )}
          {showAdditionalFields && (
            <div>
              <AddressForm {...methods} />
              <FieldDiv>
                <TextField
                  validationError={emailValidationError}
                  name="emailAddress"
                  label="Representative email"
                  inputRef={register}
                  optional
                  strongLabel
                />
              </FieldDiv>
              <PhoneNumber>
                <TextField
                  name="phoneNumber"
                  label="Phone number"
                  inputRef={register}
                  optional
                  strongLabel
                />
              </PhoneNumber>
            </div>
          )}
        </form>
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

const FieldDiv = styled.div`
  margin-bottom: 1.5em;
`;

const Suffix = styled.div`
  max-width: 8em;
`;

const PhoneNumber = styled.div`
  width: 240px;
  margin-bottom: 2em;
`;

const ClaimantAddress = styled.div`
  margin-top: 1.5em;
`;
