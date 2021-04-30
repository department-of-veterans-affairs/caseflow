/* eslint-disable */
// REMOVE ABOVE LINE BEFORE CONTINUING WORK ON THIS FILE

import React from 'react';
import PropTypes from 'prop-types';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  SUBSTITUTE_APPELLANT_SELECT_POA_TITLE,
  SUBSTITUTE_APPELLANT_SELECT_APPELLANT_SUBHEAD,
} from 'app/../COPY';
import CheckoutButtons from 'app/queue/docketSwitch/grant/CheckoutButtons';
import { pageHeader } from '../styles';

const schema = yup.object().shape({});

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
        <section className={pageHeader}>
          <h1>{SUBSTITUTE_APPELLANT_SELECT_POA_TITLE}</h1>
          <div>{SUBSTITUTE_APPELLANT_SELECT_APPELLANT_SUBHEAD}</div>
        </section>
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
/* eslint-enable */
