import React from 'react';
import PropTypes from 'prop-types';
import { FormProvider, useFieldArray, useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { AddAdminTaskForm } from 'app/queue/colocatedTasks/AddAdminTaskForm/AddAdminTaskForm';
import {
  SUBSTITUTE_APPELLANT_CREATE_TASKS_TITLE,
  SUBSTITUTE_APPELLANT_SELECT_APPELLANT_SUBHEAD,
} from 'app/../COPY';
import CheckoutButtons from 'app/queue/docketSwitch/grant/CheckoutButtons';
import Button from 'app/components/Button';
import { KeyDetails } from './KeyDetails';

const schema = yup.object().shape({
  newTasks: yup.array(
    yup.object().shape({
      type: yup.string().required(),
      instructions: yup.string().required(),
    })
  ),
});

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
  const methods = useForm({
    // Use this for repopulating form from redux when user navigates back
    defaultValues: {
      ...existingValues,
      newTasks: existingValues?.newTasks ?? [],
    },
    resolver: yupResolver(schema),
  });
  const { control, handleSubmit } = methods;

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'newTasks',
  });

  return (
    <FormProvider {...methods}>
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

          <React.Fragment>
            <h3 {...css({ marginBottom: '0' })}>
              <br />
              <strong>Would you like to add any additional tasks?</strong>
              <br />
            </h3>
            <div>
              {fields.map((item, idx) => (
                <AddAdminTaskForm
                  key={item.id}
                  item={item}
                  baseName={`newTasks[${idx}]`}
                  onRemove={() => remove(idx)}
                />
              ))}
            </div>
            <Button
              willNeverBeLoading
              dangerStyling
              styling={css({ marginTop: '1rem' })}
              name="+ Add task"
              onClick={() => append({ type: null, instructions: '' })}
            />
          </React.Fragment>
        </AppSegment>
        <div className="controls cf-app-segment">
          <CheckoutButtons
            onCancel={onCancel}
            onBack={onBack}
            onSubmit={handleSubmit(onSubmit)}
            submitText="Continue"
          />
        </div>
      </form>
    </FormProvider>
  );
};
SubstituteAppellantTasksForm.propTypes = {
  appealId: PropTypes.string,
  existingValues: PropTypes.shape({}),
  nodDate: PropTypes.oneOfType([PropTypes.instanceOf(Date), PropTypes.string]),
  dateOfDeath: PropTypes.oneOfType([
    PropTypes.instanceOf(Date),
    PropTypes.string,
  ]),
  substitutionDate: PropTypes.oneOfType([
    PropTypes.instanceOf(Date),
    PropTypes.string,
  ]),
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
};
