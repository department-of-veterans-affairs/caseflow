/* eslint-disable */
// REMOVE ABOVE LINE BEFORE CONTINUING WORK ON THIS FILE

import React from 'react';
import PropTypes from 'prop-types';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  SUBSTITUTE_APPELLANT_CREATE_TASKS_TITLE,
  SUBSTITUTE_APPELLANT_SELECT_APPELLANT_SUBHEAD,
} from 'app/../COPY';
import CheckoutButtons from 'app/queue/docketSwitch/grant/CheckoutButtons';
import { KeyDetails } from './KeyDetails';

const schema = yup.object().shape({});

const sectionStyle = css({ marginBottom: '24px' });

export const SubstituteAppellantTasksForm = ({
  appealId,
  existingValues,
  nodDate,
  dateOfDeath,
  substitutionDate,
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
        <h1>{SUBSTITUTE_APPELLANT_CREATE_TASKS_TITLE}</h1>
        <div {...sectionStyle}>
          {SUBSTITUTE_APPELLANT_SELECT_APPELLANT_SUBHEAD}
        </div>
        <KeyDetails
          appealId={appealId}
          nodDate={nodDate}
          dateOfDeath={dateOfDeath}
          substitutionDate={substitutionDate}
        />
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
SubstituteAppellantTasksForm.propTypes = {
  appealId: PropTypes.string,
  existingValues: PropTypes.shape({}),
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
};
/* eslint-enable */
