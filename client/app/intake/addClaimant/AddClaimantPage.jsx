import React from 'react';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import { Controller } from 'react-hook-form';

import SearchableDropdown from 'app/components/SearchableDropdown';
import RadioField from 'app/components/RadioField';
import TextField from 'app/components/TextField';
import AddressForm from 'app/components/AddressForm';
import { useAddClaimantForm } from './utils';
import * as Constants from '../constants';

const field = css({
  marginBottom: '1.5em',
});

const suffix = css({
  maxWidth: '8em',
});

const phoneNumber = css({
  width: '240px',
  marginBottom: '2em'
});

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

export const AddClaimantPage = ({ methods }) => {
  const {
    control,
    register,
    watch,
    handleSubmit,
  } = methods || useAddClaimantForm();

  const onSubmit = (formData) => {
    // Update this to...
    // Add claimant info to Redux
    // Probably handle submission of both claimant and remaining intake info (from Review step)
    return formData;
  };

  const watchPartyType = watch('partyType');
  const watchRelationship = watch('relationship')?.value;

  const showIndividualNameFields = watchPartyType === 'individual' || ['spouse', 'child'].includes(watchRelationship);
  const showPartyType = ['other', 'attorney'].includes(watchRelationship);
  const showAdditionalFields = watchPartyType || ['spouse', 'child'].includes(watchRelationship);

  return (
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
        <div id="names">
          <TextField
            name="firstName"
            label="First name"
            inputRef={register}
            strongLabel
            {...field}
          />
          <TextField
            name="middleName"
            label="Middle name/initial"
            inputRef={register}
            optional
            strongLabel
            {...field}
          />
          <TextField
            name="lastName"
            label="Last name"
            inputRef={register}
            optional
            strongLabel
            {...field}
          />
          <TextField
            name="suffix"
            label="Suffix"
            inputRef={register}
            optional
            strongLabel
            {...suffix}
          />
        </div>
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
          <TextField
            name="email"
            label="Claimant email"
            inputRef={register}
            optional
            strongLabel
            {...field}
          />
          <TextField
            name="phoneNumber"
            label="Phone number"
            inputRef={register}
            optional
            strongLabel
            {...phoneNumber}
          />
          <RadioField
            options={Constants.BOOLEAN_RADIO_OPTIONS}
            vertical
            inputRef={register}
            label="Do you have a VA Form 21-22 for this claimant?"
            name="vaForm"
            strongLabel
          />
        </>
      }
    </form>
  );
};

AddClaimantPage.propTypes = {
  methods: PropTypes.object
};
