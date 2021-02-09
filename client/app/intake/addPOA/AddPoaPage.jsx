import React from 'react';
import { FormProvider, Controller } from 'react-hook-form';
import { useAddClaimantForm } from '../addClaimant/utils';
import { ADD_CLAIMANT_POA_PAGE_DESCRIPTION } from 'app/../COPY';
import { IntakeLayout } from '../components/IntakeLayout';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { AddClaimantButtons } from '../addClaimant/AddClaimantButtons';
import styled from 'styled-components';
import { useHistory } from 'react-router';
import _, { debounce } from 'lodash';
import ApiUtil from '../../util/ApiUtil';

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

const getRepresentativeOpts = async (search = '', asyncFn) => {
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

const filterOption = () => true;

const asyncFn = useCallback(
  debounce((search, callback) => {
    getAttorneyClaimantOpts(search, fetchAttorneys).then((res) => callback(res));
  }, 250),
  [fetchAttorneys]
);

export const AddPoaPage = () => {
  const methods = useAddClaimantForm();
  const { goBack, push } = useHistory();

  const {
    control,
    register,
    watch,
    formState: { isValid },
    handleSubmit,
  } = methods;

  const onSubmit = (formData) => {

  };

  const handleBack = () => goBack();

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
            name="listedRepresentative"
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
