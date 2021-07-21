import React, {useMemo} from 'react';
import PropTypes from 'prop-types';
import { FormProvider, useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import ReactMarkdown from 'react-markdown';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  SUBSTITUTE_APPELLANT_CREATE_TASKS_TITLE,
  SUBSTITUTE_APPELLANT_SELECT_APPELLANT_SUBHEAD,
  SUBSTITUTE_APPELLANT_TASK_SELECTION_TITLE,
  SUBSTITUTE_APPELLANT_TASK_SELECTION_DESCRIPTION,
} from 'app/../COPY';
import CheckoutButtons from 'app/queue/docketSwitch/grant/CheckoutButtons';
import { KeyDetails } from './KeyDetails';
import { pageHeader, sectionStyle } from '../styles';
import { TaskSelectionTable } from './TaskSelectionTable';
import { disabledTasksBasedOnSelections } from "app/queue/substituteAppellant/tasks/utils";

const schema = yup.object().shape({
  taskIds: yup.array(yup.number()),
});

export const SubstituteAppellantTasksForm = ({
  appealId,
  existingValues,
  nodDate,
  dateOfDeath,
  substitutionDate,
  onBack,
  onCancel,
  onSubmit,
  tasks = [],
}) => {
  const methods = useForm({
    // Use this for repopulating form from redux when user navigates back
    resolver: yupResolver(schema),
    defaultValues: {
      ...existingValues,
      taskIds:
        // eslint-disable-next-line max-len
        existingValues?.taskIds?.length ? existingValues?.taskIds : (tasks?.filter((task) => task.selected)).map((task) => parseInt(task.taskId, 10)),
    },
  });

  const { handleSubmit, watch } = methods;
  const selectedTaskIds = watch('taskIds');

  const adjustedTasks = useMemo(() =>
    disabledTasksBasedOnSelections({tasks, selectedTaskIds}),
  [tasks, selectedTaskIds]
  );

  return (
    <FormProvider {...methods}>
      <form onSubmit={handleSubmit(onSubmit)}>
        <AppSegment filledBackground>
          <section className={pageHeader}>
            <h1>{SUBSTITUTE_APPELLANT_CREATE_TASKS_TITLE}</h1>
            <div>{SUBSTITUTE_APPELLANT_SELECT_APPELLANT_SUBHEAD}</div>
          </section>
          <KeyDetails
            className={sectionStyle}
            appealId={appealId}
            nodDate={nodDate}
            dateOfDeath={dateOfDeath}
            substitutionDate={substitutionDate}
          />

          <div className={sectionStyle}>
            <h2>{SUBSTITUTE_APPELLANT_TASK_SELECTION_TITLE}</h2>
            <div><ReactMarkdown source={SUBSTITUTE_APPELLANT_TASK_SELECTION_DESCRIPTION} /></div>
            <TaskSelectionTable tasks={adjustedTasks} />
          </div>
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
  tasks: PropTypes.arrayOf(
    PropTypes.shape({
      appealId: PropTypes.number,
      closedAt: PropTypes.oneOfType([
        PropTypes.string,
        PropTypes.instanceOf(Date),
      ]),
      externalAppealId: PropTypes.string,
      parentId: PropTypes.number,
      taskId: PropTypes.oneOfType[(PropTypes.string, PropTypes.number)],
      type: PropTypes.string,
    })
  ),
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
};
