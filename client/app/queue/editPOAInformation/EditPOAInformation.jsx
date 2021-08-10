import React, { Fragment, useEffect, useState } from 'react';
import { FormProvider } from 'react-hook-form';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { connect, useDispatch, useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import { useHistory } from 'react-router';
import { sprintf } from 'sprintf-js';
import { isEmpty } from 'lodash';

import { ClaimantForm as EditClaimantForm } from '../../intake/addClaimant/ClaimantForm';
import { useClaimantForm } from '../../intake/addClaimant/utils';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import COPY from 'app/../COPY';
import { appealWithDetailSelector } from '../selectors';
import { mapAppellantDataFromApi, mapAppellantDataToApi, mapPOADataFromApi } from './utils';
import { resetSuccessMessages,
  showSuccessMessage,
} from '../uiReducer/uiActions';
import ApiUtil from '../../util/ApiUtil';
import { clearAppealDetails } from '../QueueActions';

const getDefaultValues = (appeal, POA = false) => {
  return(
    POA ? mapPOADataFromApi(appeal) : mapAppellantDataFromApi(appeal)
  )
}

const EditPOAInformation = ({ appealId, POA }) => {
  const dispatch = useDispatch();
  const { goBack, push } = useHistory();
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  useEffect(() => {
    dispatch(resetSuccessMessages());
  }, []);

  const defaultValues = getDefaultValues(appeal, POA);

  const methods = useClaimantForm({ defaultValues }, true, true, POA);
  const [loading, setLoading] = useState(false);
  const [editFailure, setEditFailure] = useState(false);

  const {
    formState: { isValid, errors },
    handleSubmit,
  } = methods;

  const handleUpdate = (formData) => {
    const appellantId = appeal.unrecognizedAppellantId;
    const updatePayload = mapAppellantDataToApi(formData);

    setLoading(true);

    ApiUtil.patch(`/power_of_attorney/${appellantId}`, { data: updatePayload }).then((response) => {
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
    // eslint-disable-next-line no-unused-vars
    (error) => {
      // eslint-disable-next-line no-console
      setEditFailure(true);
      setLoading(false);
    });
  };

  const editAppellantHeader = 'Edit Appellant Information';
  const editPOAHeader = defaultValues.firstName ? "Edit Appellant's POA Information" : "Update Appellant's POA";
  const editAppellantDescription = COPY.EDIT_CLAIMANT_PAGE_DESCRIPTION;
  const editPOADescription = defaultValues.firstName ? editAppellantDescription : COPY.UPDATE_POA_PAGE_DESCRIPTION;

  return <div>
    <FormProvider {...methods}>
      <AppSegment filledBackground>
        {editFailure === true &&
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
          editAppellantHeader={POA ? editPOAHeader : editAppellantHeader}
          editAppellantDescription={POA ? editPOADescription : editAppellantDescription}
          hidePOAForm
          hideListedAttorney={!POA}
          POA={POA}
        />
      </AppSegment>
      <Button
        onClick={handleSubmit(handleUpdate)}
        classNames={['cf-right-side']}
        loading={loading}
        disabled={!isValid || (!POA && !isValid && !isEmpty(errors))}
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

EditPOAInformation.propTypes = {
  appealId: PropTypes.string
};

export default connect()(EditPOAInformation);
