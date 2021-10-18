import React, { Fragment, useEffect, useState } from 'react';
import { FormProvider } from 'react-hook-form';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { connect, useDispatch, useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import { useHistory } from 'react-router';

import Alert from '../../components/Alert';
import Button from '../../components/Button';
import { ClaimantForm as EditClaimantForm } from '../../intake/addClaimant/ClaimantForm';
import { EDIT_CLAIMANT_PAGE_DESCRIPTION,
  EDIT_POA_SUCCESS_ALERT_TITLE,
  EDIT_POA_SUCCESS_ALERT_MESSAGE,
  EDIT_UNRECOGNIZED_APPELLANT_FAILURE_ALERT_TITLE,
  UPDATE_POA_PAGE_DESCRIPTION } from 'app/../COPY';

import { clearAppealDetails } from '../QueueActions';
import { appealWithDetailSelector } from '../selectors';
import { resetSuccessMessages, showSuccessMessage } from '../uiReducer/uiActions';

import ApiUtil from '../../util/ApiUtil';
import { mapPOADataToApi, mapPOADataFromApi } from './utils';
import { useClaimantForm } from '../../intake/addClaimant/utils';

const EditPOAInformation = ({ appealId }) => {
  const dispatch = useDispatch();
  const { goBack, push } = useHistory();
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  useEffect(() => {
    dispatch(resetSuccessMessages());
  }, []);

  const defaultValues = mapPOADataFromApi(appeal);

  const methods = useClaimantForm({ defaultValues }, true, true);
  const [loading, setLoading] = useState(false);
  const [editFailure, setEditFailure] = useState(false);

  const {
    formState: { isValid },
    handleSubmit,
  } = methods;

  const handleUpdate = (formData) => {
    const appellantId = appeal.unrecognizedAppellantId;
    const updatePayload = mapPOADataToApi(formData);

    setLoading(true);

    ApiUtil.patch(`/unrecognized_appellants/${appellantId}/power_of_attorney`, { data: updatePayload }).then(() => {
      dispatch(clearAppealDetails(appealId));
      push(`/queue/appeals/${appealId}`);

      dispatch(showSuccessMessage({
        title: EDIT_POA_SUCCESS_ALERT_TITLE,
        detail: EDIT_POA_SUCCESS_ALERT_MESSAGE
      }));
    },
    // eslint-disable-next-line no-unused-vars
    (error) => {
      setEditFailure(true);
      setLoading(false);
    });
  };
  const editPOAHeader = defaultValues.firstName ? "Edit Appellant's POA Information" : "Update Appellant's POA";
  const editPOADescription = defaultValues.firstName ?
    EDIT_CLAIMANT_PAGE_DESCRIPTION : UPDATE_POA_PAGE_DESCRIPTION;

  return <div>
    <FormProvider {...methods}>
      <AppSegment filledBackground>
        {editFailure === true &&
          <Alert
            type="error"
            title={EDIT_UNRECOGNIZED_APPELLANT_FAILURE_ALERT_TITLE}
            message={
              <Fragment>Please try again and if this error persists,
                <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer"> submit a YourIT ticket</a>
              </Fragment>
            }
          />
        }
        <EditClaimantForm
          editAppellantHeader={editPOAHeader}
          editAppellantDescription={editPOADescription}
          hidePOAForm
          POA
        />
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
      </AppSegment>
    </FormProvider>
  </div>;
};

EditPOAInformation.propTypes = {
  appealId: PropTypes.string
};

export default connect()(EditPOAInformation);
