import React, { useState } from 'react';
import { FormProvider } from 'react-hook-form';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { connect, useDispatch, useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import { useHistory } from 'react-router';

import { ClaimantForm as EditClaimantForm } from '../../intake/addClaimant/ClaimantForm';
import { useClaimantForm } from '../../intake/addClaimant/utils';
import Button from '../../components/Button';
import { updateAppellantInformation } from './editAppellantInformationSlice';
import { EDIT_CLAIMANT_PAGE_DESCRIPTION } from 'app/../COPY';
import { appealWithDetailSelector } from '../selectors';
import { mapAppellantDataFromApi } from './utils';

const EditAppellantInformation = ({ appealId }) => {
  const dispatch = useDispatch();
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const { goBack } = useHistory();

  const [loading, setLoading] = useState(false)

  const methods = useClaimantForm({ defaultValues: mapAppellantDataFromApi(appeal) }, true);
  const {
    handleSubmit,
  } = methods;

  const handleUpdate = (formData) => {
    const appellantId = appeal.unrecognizedAppellantId;
    setLoading(true)
    dispatch(updateAppellantInformation({ formData, appellantId, appealId }));
  };

  const handleBack = () => goBack();

  const editAppellantHeader = 'Edit Appellant Information';
  const editAppellantDescription = EDIT_CLAIMANT_PAGE_DESCRIPTION;

  return <div>
    <FormProvider {...methods}>
      <AppSegment filledBackground>
        <EditClaimantForm
          editAppellantHeader={editAppellantHeader}
          editAppellantDescription={editAppellantDescription}
          hidePOAForm
        />
      </AppSegment>
      <Button
        onClick={handleSubmit(handleUpdate)}
        classNames={['cf-right-side']}
        loading={loading}
        name='Save'
      >
        Save
      </Button>
      <Button
        onClick={handleBack}
        classNames={['cf-right-side', 'usa-button-secondary']}
        styling={{ style: { marginRight: '1em' } }}
      >
        Cancel
      </Button>
    </FormProvider>
  </div>;
};

EditAppellantInformation.propTypes = {
  appealId: PropTypes.string
};

export default connect()(EditAppellantInformation);
