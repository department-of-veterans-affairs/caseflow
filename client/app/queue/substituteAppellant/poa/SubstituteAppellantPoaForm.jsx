import React from 'react';
import PropTypes from 'prop-types';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  SUBSTITUTE_APPELLANT_SELECT_POA_TITLE,
  SUBSTITUTE_APPELLANT_SELECT_APPELLANT_SUBHEAD,
} from 'app/../COPY';
import CheckoutButtons from 'app/queue/docketSwitch/grant/CheckoutButtons';

const schema = yup.object().shape({});

const sectionStyle = css({ marginBottom: '24px' });

export const SubstituteAppellantPoaForm = ({
  existingValues,
  onBack,
  onCancel,
  onSubmit,
}) => {
  const {
    errors,
    formState: { touched },
    handleSubmit,
    register,
  } = useForm({
    // Use this for repopulating form from redux when user navigates back
    defaultValues: { ...existingValues },
    resolver: yupResolver(schema),
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <AppSegment filledBackground>
        <h1>{SUBSTITUTE_APPELLANT_SELECT_POA_TITLE}</h1>
        <div {...sectionStyle}>
          {SUBSTITUTE_APPELLANT_SELECT_APPELLANT_SUBHEAD}
        </div>
      </AppSegment>
      <div className="controls cf-app-segment">
        <CheckoutButtons
          onCancel={onCancel}
          onBack={onBack}
          onSubmit={onSubmit}
          submitText="Continue"
        />
      </div>
    </form>
  );
};
SubstituteAppellantPoaForm.propTypes = {
  existingValues: PropTypes.shape({}),
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
};
