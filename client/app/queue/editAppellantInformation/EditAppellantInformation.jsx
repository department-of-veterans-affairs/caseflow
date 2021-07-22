import React, { Fragment, useEffect, useState } from 'react';
import { FormProvider } from 'react-hook-form';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { connect, useDispatch, useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import { useHistory } from 'react-router';
import { sprintf } from 'sprintf-js';

import { ClaimantForm as EditClaimantForm } from '../../intake/addClaimant/ClaimantForm';
import { useClaimantForm } from '../../intake/addClaimant/utils';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import COPY from 'app/../COPY';
import { appealWithDetailSelector } from '../selectors';
import { mapAppellantDataFromApi, mapAppellantDataToApi } from './utils';
import { resetSuccessMessages,
  showSuccessMessage,
} from '../uiReducer/uiActions';
import ApiUtil from '../../util/ApiUtil';
import { clearAppealDetails } from '../QueueActions';

const EditAppellantInformation = ({ appealId }) => {
  const dispatch = useDispatch();
  const { goBack, push } = useHistory();
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  useEffect(() => {
    dispatch(resetSuccessMessages());
  }, []);

  const methods = useClaimantForm({ defaultValues: mapAppellantDataFromApi(appeal) }, true, true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(false);

  const {
    formState: { isValid },
    handleSubmit,
  } = methods;

  const handleUpdate = (formData) => {
    const appellantId = appeal.unrecognizedAppellantId;
    const appellantPayload = mapAppellantDataToApi(formData);

    setLoading(true);

    ApiUtil.patch(`/unrecognized_appellants/${appellantId}`, { data: appellantPayload }).then((response) => {
      const appellantName = response.body.unrecognized_party_detail.name;

      const title = sprintf(COPY.EDIT_UNRECOGNIZED_APPELLANT_SUCCESS_ALERT_TITLE, { appellantName });
      const detail = COPY.EDIT_UNRECOGNIZED_APPELLANT_SUCCESS_ALERT_MESSAGE;

      const successMessage = {
        title,
        detail,
      };

      dispatch(clearAppealDetails(appealId));
      dispatch(showSuccessMessage(successMessage));
      push(`/queue/appeals/${appealId}`);
    },
    (_error) => {
      // eslint-disable-next-line no-console
      setError(true);
      setLoading(false);
    });
  };

  const editAppellantHeader = 'Edit Appellant Information';
  const editAppellantDescription = COPY.EDIT_CLAIMANT_PAGE_DESCRIPTION;

  return <div>
    <FormProvider {...methods}>
      <AppSegment filledBackground>
        {error === true &&
          <Alert
            type="error"
            title={COPY.EDIT_UNRECOGNIZED_APPELLANT_FAILURE_ALERT_TITLE}
            message={
              <Fragment>Please try again and if this error persists,
                <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer"> submit a YourIT ticket</a>
              </Fragment>
            }
          />
        }
        <EditClaimantForm
          editAppellantHeader={editAppellantHeader}
          editAppellantDescription={editAppellantDescription}
          hidePOAForm
          hideListedAttorney
        />
      </AppSegment>
      <Button
        onClick={handleSubmit(handleUpdate)}
        classNames={['cf-right-side']}
        loading={loading}
        disabled={!isValid}
        name="Save"
      >
        Save
      </Button>
      <Button
        onClick={goBack}
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
