import React, { useCallback } from 'react';
import { FormProvider, Controller } from 'react-hook-form';
import { useAddPoaForm } from './utils';
import { ADD_CLAIMANT_POA_PAGE_DESCRIPTION } from 'app/../COPY';
import { IntakeLayout } from '../components/IntakeLayout';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { AddClaimantButtons } from '../addClaimant/AddClaimantButtons';
import styled from 'styled-components';
import { useHistory } from 'react-router';
import { debounce, reduce, startCase, camelCase } from 'lodash';
import ApiUtil from '../../util/ApiUtil';
import RadioField from 'app/components/RadioField';
import Address from 'app/queue/components/Address';
import AddressForm from 'app/components/AddressForm';
import TextField from 'app/components/TextField';

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
    return reduce(bgsAddress, (result, value, key) => {
      result[key] = startCase(camelCase(value));
      if (['state', 'country'].includes(key)) {
        result[key] = value;
      } else {
        result[key] = startCase(camelCase(value));
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

const filterOption = () => true;

export const AddPoaPage = () => {

  const methods = useAddPoaForm();
  const {
    control,
    register,
    watch,
    formState: { isValid },
    handleSubmit,
  } = methods;

  const { goBack } = useHistory();
  const onSubmit = (formData) => {
    return formData;
  };
  const handleBack = () => goBack();

  const watchPartyType = watch('partyType');
  const showAdditionalFields = watchPartyType;
  const showIndividualNameFields = watchPartyType === 'individual';

  const listedAttorney = watch('listedAttorney');
  const attorneyNotListed = listedAttorney?.value === 'not_listed';
  const showPartyType = attorneyNotListed;
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
        <h1>Add Claimant's POA</h1>
        <p>{ADD_CLAIMANT_POA_PAGE_DESCRIPTION}</p>

        <form onSubmit={handleSubmit(onSubmit)}>
          <h2>Representative</h2>
          <Controller
            control={control}
            name="listedAttorney"
            defaultValue={null}
            render={({ ...rest }) => (
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
            )}
          />

          { listedAttorney?.address &&
        <div>
          <ClaimantAddress>
            <strong>Representative's address</strong>
          </ClaimantAddress>
          <br />
          <Address address={listedAttorney?.address} />
        </div>
          }

          { showPartyType &&
        <RadioField
          name="partyType"
          label="Is the representative an organization or individual?"
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
          {showAdditionalFields &&
       <div>
         <AddressForm {...methods} />
         <FieldDiv>
           <TextField
             name="email"
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
