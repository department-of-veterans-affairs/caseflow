import React from 'react';
import PropTypes from 'prop-types';
import { FormProvider, useForm } from 'react-hook-form';
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
import { TasksToReActivate } from './TasksToReActivate';
import { TasksToCancel } from './TasksToCancel';

export const EditCavcRemandTasksForm = ({
  appealId,
  existingValues,
  nodDate,
  dateOfDeath,
  substitutionDate,
  onBack,
  onCancel,
  onSubmit,
  setSelectedCancelTaskIds,
  setSelectedReActivateTaskIds,
  cancelledOrCompletedTasks = [],
  activeTasks = []
}) => {
  const methods = useForm({
    defaultValues: {
      ...existingValues,
      cancelTaskIds: existingValues?.cancelTaskIds,
      reActivateTaskIds: existingValues?.reActivateTaskIds,
    },
  });

  const { handleSubmit } = methods;

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
            isAppellantSubstituted={existingValues.isAppellantSubstituted}
          />
          <div className={sectionStyle}>
            { activeTasks?.length > 0 && (
              <div className={sectionStyle}>
                <h2>{CAVC_REMAND_MODIFY_TASKS_APPEAL_TASKS_TITLE}</h2>
                <br></br>
                <div className={sectionStyle}>
                  <div><strong>{CAVC_REMAND_MODIFY_TASKS_ACTIVE_TITLE}</strong></div>
                  <div><ReactMarkdown source={CAVC_REMAND_MODIFY_TASKS_ACTIVE_DETAIL} /></div>
                  <TasksToCancel
                    tasks={activeTasks}
                    existingValues={existingValues}
                    setSelectedCancelTaskIds={setSelectedCancelTaskIds}
                  />
                </div>
              </div>
            )}
            { cancelledOrCompletedTasks?.length > 0 && (
              <div className={sectionStyle}>
                <div><strong>{CAVC_REMAND_MODIFY_TASKS_CANCELLED_TITLE}</strong></div>
                <div><ReactMarkdown source={CAVC_REMAND_MODIFY_TASKS_CANCELLED_DETAIL} /></div>
                <TasksToReActivate
                  tasks={cancelledOrCompletedTasks}
                  existingValues={existingValues}
                  setSelectedReActivateTaskIds={setSelectedReActivateTaskIds}
                />
              </div>
            )}

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
  cancelledOrCompletedTasks: PropTypes.arrayOf(
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
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  setSelectedCancelTaskIds: PropTypes.func,
};
