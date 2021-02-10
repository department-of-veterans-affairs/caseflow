import React, { useCallback } from 'react';
import { useHistory } from 'react-router';
import { FormProvider, Controller } from 'react-hook-form';
import styled from 'styled-components';
import _, { debounce } from 'lodash';
import { useDispatch } from 'react-redux';

import { IntakeLayout } from '../components/IntakeLayout';
import SearchableDropdown from 'app/components/SearchableDropdown';
import RadioField from 'app/components/RadioField';
import TextField from 'app/components/TextField';
import AddressForm from 'app/components/AddressForm';
import { AddClaimantButtons } from './AddClaimantButtons';
import * as Constants from '../constants';
import ApiUtil from '../../util/ApiUtil';
import Address from 'app/queue/components/Address';

import { useAddClaimantForm } from './utils';
import { ADD_CLAIMANT_PAGE_DESCRIPTION } from 'app/../COPY';
import { editClaimantInformation } from '../reducers/addClaimantSlice';

const relationshipOpts = [
  { value: 'attorney', label: 'Attorney (previously or currently)' },
  { value: 'child', label: 'Child' },
  { value: 'spouse', label: 'Spouse' },
  { value: 'other', label: 'Other' },
];

const partyTypeOpts = [
  { displayText: 'Organization', value: 'organization' },
  { displayText: 'Individual', value: 'individual' }
];

const fetchAttorneys = async (search = '') => {
  const res = await ApiUtil.get('/intake/attorneys', {
    query: { query: search }
  });

  return res?.body;
};

const getAttorneyClaimantOpts = async (search = '', asyncFn) => {
  // Enforce minimum search length (we'll simply return empty array rather than throw error)
  if (search.length < 3) {
    return [];
  }

  const formatAddress = (bgsAddress) => {
    return _.reduce(bgsAddress, (result, value, key) => {
      result[key] = _.startCase(_.camelCase(value));
      if (['state', 'country'].includes(key)) {
        result[key] = value;
      } else {
        result[key] = _.startCase(_.camelCase(value));
      }

      return result;
    }, {});
  };

  const res = await asyncFn(search);
  const options = res.map((item) => ({
    label: item.name,
    value: item.participant_id,
    address: formatAddress(item.address),
  }));

  options.push({ label: 'Name not listed', value: 'not_listed' });

  return options;
};
// We'll show all items returned from the backend instead of using default substring matching
const filterOption = () => true;

export const AddClaimantPage = () => {
  const dispatch = useDispatch();
  const { goBack, push } = useHistory();
  const methods = useAddClaimantForm();
  const {
    control,
    register,
    watch,
    formState: { isValid },
    handleSubmit,
  } = methods;
  const onSubmit = (formData) => {

    // Add stuff to redux store
    dispatch(editClaimantInformation({ formData }));

    if (formData.vaForm === 'true') {
      push('/add_power_of_attorney');
    } else {
      push('/add_issues');
    }
    // Update this to...
    // Add claimant info to Redux
    // Probably handle submission of both claimant and remaining intake info (from Review step)
    // return formData;
  };

  const handleBack = () => goBack();

  const watchPartyType = watch('partyType');
  const watchRelationship = watch('relationship')?.value;

  const showIndividualNameFields = watchPartyType === 'individual' || ['spouse', 'child'].includes(watchRelationship);
  const listedAttorney = watch('listedAttorney');
  const attorneyNotListed = listedAttorney?.value === 'not_listed';
  const showPartyType = watchRelationship === 'other' || attorneyNotListed;
  const showAdditionalFields = watchPartyType || ['spouse', 'child'].includes(watchRelationship);

  const asyncFn = useCallback(
    debounce((search, callback) => {
      getAttorneyClaimantOpts(search, fetchAttorneys).then((res) => callback(res));
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
        <h1>Add Claimant</h1>
        <p>{ADD_CLAIMANT_PAGE_DESCRIPTION}</p>

        <form onSubmit={handleSubmit(onSubmit)}>
          <Controller
            control={control}
            name="relationship"
            label="Relationship to the Veteran"
            options={relationshipOpts}
            strongLabel
            as={SearchableDropdown}
          />
          <br />
          { watchRelationship === 'attorney' &&
            <>
              <Controller
                control={control}
                name="listedAttorney"
                defaultValue={null}
                render={({ ...rest }) => (
                  <SearchableDropdown
                    {...rest}
                    label="Claimant's name"
                    filterOption={filterOption}
                    async={asyncFn}
                    defaultOptions
                    debounce={250}
                    strongLabel
                    isClearable
                    placeholder="Type to search..."
                  />
                )}
              />
            </>
          }

          { listedAttorney?.address &&
            <div>
              <ClaimantAddress>
                <strong>Claimant's address</strong>
              </ClaimantAddress>
              <br />
              <Address address={listedAttorney?.address} />
            </div>
          }

          { showPartyType &&
            <RadioField
              name="partyType"
              label="Is the claimant an organization or individual?"
              inputRef={register}
              strongLabel
              vertical
              options={partyTypeOpts}
            />
          }
          <br />
          { showIndividualNameFields &&
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
          }
          { watchPartyType === 'organization' &&
            <TextField
              name="organization"
              label="Organization name"
              inputRef={register}
              strongLabel
            />
          }
          { showAdditionalFields &&
            <>
              <AddressForm {...methods} />
              <FieldDiv>
                <TextField
                  name="email"
                  label="Claimant email"
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
            </>
          }
          { (showAdditionalFields || listedAttorney) &&
            <RadioField
              options={Constants.BOOLEAN_RADIO_OPTIONS}
              vertical
              inputRef={register}
              label="Do you have a VA Form 21-22 for this claimant?"
              name="vaForm"
              strongLabel
            />
          }
        </form>
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
