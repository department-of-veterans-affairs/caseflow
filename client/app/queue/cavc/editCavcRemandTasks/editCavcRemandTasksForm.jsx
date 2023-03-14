import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { FormProvider, useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import ReactMarkdown from 'react-markdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  CAVC_REMAND_MODIFY_TASKS_TITLE,
  CAVC_REMAND_MODIFY_TASKS_SUBHEAD,
  CAVC_REMAND_MODIFY_TASKS_APPEAL_TASKS_TITLE,
  CAVC_REMAND_MODIFY_TASKS_ACTIVE_TITLE,
  CAVC_REMAND_MODIFY_TASKS_ACTIVE_DETAIL,
  CAVC_REMAND_MODIFY_TASKS_CANCELLED_TITLE,
  CAVC_REMAND_MODIFY_TASKS_CANCELLED_DETAIL,
  CAVC_REMAND_MODIFY_TASKS_OTHER_TASKS
} from 'app/../COPY';
import CheckoutButtons from 'app/queue/docketSwitch/grant/CheckoutButtons';
import { KeyDetails } from './KeyDetails';
import { pageHeader, sectionStyle } from '../styles';
import { ScheduleHearingTaskAlert } from './ScheduleHearingTaskAlert';
import { taskTypesSelected, disabledTasksBasedOnSelections, adjustOpenTasksBasedOnSelection } from './utils';
import { TasksToCopy } from './TasksToCopy';
import { TasksToCancel } from './TasksToCancel';
import { isDate, max, parseISO } from 'date-fns';

const schema = yup.object().shape({
  substitutionDate: yup.
    date().
    required('Substitution Date is required').
    nullable().
    max(new Date(), 'Date cannot be in the future').
    when(['$nodDate', '$dateOfDeath'], (date1, date2, currentSchema) => {
      // We want to ensure that selected date is after the NOD and date of death
      // Date of death may not actually be set, so we first filter out undefined from these values
      // eslint-disable-next-line id-length
      const dates = [date1, date2].filter(Boolean).map((d) => (isDate(d) ? d : parseISO(d)));

      return currentSchema.min(max(dates), "Date cannot be earlier than the NOD date or the Veteran's date of death");
    }).
    transform((value, originalValue) => (originalValue === '' ? null : value)),
  closedTaskIds: yup.array(yup.number()),
  openTaskIds: yup.array(yup.number()),
});

export const EditCavcRemandTasksForm = ({
  appealId,
  existingValues,
  nodDate,
  dateOfDeath,
  substitutionDate,
  onBack,
  onCancel,
  onSubmit,
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
            <h1>{CAVC_REMAND_MODIFY_TASKS_TITLE}</h1>
            <div>{CAVC_REMAND_MODIFY_TASKS_SUBHEAD}</div>
          </section>
          <KeyDetails
            className={sectionStyle}
            appealId={appealId}
            nodDate={nodDate}
            dateOfDeath={dateOfDeath}
            substitutionDate={substitutionDate}
          />

          <div className={sectionStyle}>
            <h2>{CAVC_REMAND_MODIFY_TASKS_APPEAL_TASKS_TITLE}</h2>
            <br></br>
            {(
              <div className={sectionStyle}>
                <div><strong>{CAVC_REMAND_MODIFY_TASKS_ACTIVE_TITLE}</strong></div>
                <div><ReactMarkdown source={CAVC_REMAND_MODIFY_TASKS_ACTIVE_DETAIL} /></div>
                <TasksToCancel tasks={adjustedOpenTasks} />
              </div>
            )}

            <div className={sectionStyle}>
              <div><strong>{CAVC_REMAND_MODIFY_TASKS_CANCELLED_TITLE}</strong></div>
              <div><ReactMarkdown source={CAVC_REMAND_MODIFY_TASKS_CANCELLED_DETAIL} /></div>
              <TasksToCopy tasks={adjustedTasks} />
            </div>

            <div className={sectionStyle}>
              <div>{CAVC_REMAND_MODIFY_TASKS_OTHER_TASKS}</div>
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
EditCavcRemandTasksForm.propTypes = {
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
