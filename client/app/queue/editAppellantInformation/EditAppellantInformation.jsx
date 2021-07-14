import React from 'react';
import { FormProvider } from 'react-hook-form';
import { lowerCase } from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { connect, useDispatch, useSelector } from 'react-redux';
import PropTypes from 'prop-types';

import { ClaimantForm as EditClaimantForm } from '../../intake/addClaimant/ClaimantForm';
import { useClaimantForm } from '../../intake/addClaimant/utils';
import Button from '../../components/Button';
import { updateAppellantInformation } from './editAppellantInformationSlice';
import { EDIT_CLAIMANT_PAGE_DESCRIPTION } from 'app/../COPY';
import { appealWithDetailSelector } from '../selectors';

const prepareAppellantInformation = (appeal) => {
  return {
    relationship: lowerCase(appeal.appellantRelationship),
    partyType: appeal.appellantPartyType,
    name: appeal.appellantFullName,
    firstName: appeal.appellantFirstName,
    middleName: appeal.appellantMiddleName,
    lastName: appeal.appellantLastName,
    suffix: appeal.appellantSuffix,
    addressLine1: appeal.appellantAddress.address_line_1,
    addressLine2: appeal.appellantAddress.address_line_2,
    addressLine3: appeal.appellantAddress.address_line_3,
    city: appeal.appellantAddress.city,
    state: appeal.appellantAddress.state,
    zip: appeal.appellantAddress.zip,
    country: appeal.appellantAddress.country,
    phoneNumber: appeal.appellantPhoneNumber,
    emailAddress: appeal.appellantEmailAddress,
    poaForm: (appeal.appellantUnrecognizedPOAId !== null).toString()
  };
};

const EditAppellantInformation = ({ appealId }) => {
  const dispatch = useDispatch();
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const methods = useClaimantForm({ defaultValues: prepareAppellantInformation(appeal) });
  const {
    handleSubmit,
  } = methods;

  const handleUpdate = (formData) => {
    const id = appeal.unrecognizedAppellantId;

    dispatch(updateAppellantInformation({ formData, id }));
  };

  const editAppellantHeader = 'Edit Appellant Information';
  const editAppellantDescription = EDIT_CLAIMANT_PAGE_DESCRIPTION;

  return <div>
    <FormProvider {...methods}>
      <AppSegment filledBackground>
        <EditClaimantForm
          editAppellantHeader={editAppellantHeader}
          editAppellantDescription={editAppellantDescription}
        />
        <Button onClick={handleSubmit(handleUpdate)}>Submit</Button>
      </AppSegment>
    </FormProvider>
  </div>;
};

EditAppellantInformation.propTypes = {
  appealId: PropTypes.string
};

export default connect()(EditAppellantInformation);
