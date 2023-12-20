import React, { useMemo } from 'react';
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
  SUBSTITUTE_APPELLANT_ACTIVE_TASK_SELECTION_TITLE,
  SUBSTITUTE_APPELLANT_ACTIVE_TASK_SELECTION_DESCRIPTION,
  SUBSTITUTE_APPELLANT_CANCELLED_TASK_SELECTION_TITLE,
  SUBSTITUTE_APPELLANT_CANCELLED_TASK_SELECTION_DESCRIPTION,
} from 'app/../COPY';
import CheckoutButtons from 'app/queue/docketSwitch/grant/CheckoutButtons';
import { KeyDetails } from './KeyDetails';
import { pageHeader, sectionStyle } from '../styles';
import { ScheduleHearingTaskAlert } from './ScheduleHearingTaskAlert';
import { taskTypesSelected, disabledTasksBasedOnSelections, adjustOpenTasksBasedOnSelection } from './utils';
import { TasksToCopy } from './TasksToCopy';
import { TasksToCancel } from './TasksToCancel';

const schema = yup.object().shape({
  closedTaskIds: yup.array(yup.number()),
  openTaskIds: yup.array(yup.number()),
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
  pendingAppeal,
  cancelledTasks = [],
  activeTasks = []
}) => {
  const methods = useForm({
    // Use this for repopulating form from redux when user navigates back
    resolver: yupResolver(schema),
    defaultValues: {
      ...existingValues,
      closedTaskIds:
        // eslint-disable-next-line max-len
        existingValues?.closedTaskIds?.length ? existingValues?.closedTaskIds : (cancelledTasks?.filter((task) => task.selected)).map((task) => parseInt(task.taskId, 10)),
      openTaskIds:
        // eslint-disable-next-line max-len
        existingValues?.openTaskIds?.length ? existingValues?.openTaskIds : (activeTasks?.filter((task) => task.selected)).map((task) => parseInt(task.taskId, 10)),
    },
  });

  const { handleSubmit, watch } = methods;
  const selectedClosedTaskIds = watch('closedTaskIds');

  const adjustedTasks = useMemo(
    () =>
      disabledTasksBasedOnSelections({
        tasks: cancelledTasks,
        selectedTaskIds: selectedClosedTaskIds,
      }),
    [cancelledTasks, selectedClosedTaskIds]
  );

  const selectedOpenTaskIds = watch('openTaskIds');
  const adjustedOpenTasks = useMemo(
    () =>
      adjustOpenTasksBasedOnSelection({
        tasks: activeTasks,
        selectedTaskIds: selectedOpenTaskIds,
      }),
    [activeTasks, selectedOpenTaskIds]
  );

  const shouldShowScheduleHearingTaskAlert = useMemo(() => {
    return taskTypesSelected({
      tasks: cancelledTasks,
      selectedTaskIds: selectedClosedTaskIds,
    }).includes('ScheduleHearingTask');
  }, [cancelledTasks, selectedClosedTaskIds]);

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

            {pendingAppeal && (
              <div className={sectionStyle}>
                <div><strong>{SUBSTITUTE_APPELLANT_ACTIVE_TASK_SELECTION_TITLE}</strong></div>
                <div><ReactMarkdown source={SUBSTITUTE_APPELLANT_ACTIVE_TASK_SELECTION_DESCRIPTION} /></div>
                {shouldShowScheduleHearingTaskAlert && <ScheduleHearingTaskAlert /> }
                <TasksToCancel tasks={adjustedOpenTasks} />
              </div>
            )}

            <div className={sectionStyle}>
              <div><strong>{SUBSTITUTE_APPELLANT_CANCELLED_TASK_SELECTION_TITLE}</strong></div>
              <div><ReactMarkdown source={SUBSTITUTE_APPELLANT_CANCELLED_TASK_SELECTION_DESCRIPTION} /></div>
              {shouldShowScheduleHearingTaskAlert && <ScheduleHearingTaskAlert /> }
              <TasksToCopy tasks={adjustedTasks} />
            </div>
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
  cancelledTasks: PropTypes.arrayOf(
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
  activeTasks: PropTypes.arrayOf(
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
  pendingAppeal: PropTypes.bool,
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
};
