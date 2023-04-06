import React from 'react';
import PropTypes from 'prop-types';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  CAVC_REMAND_REVIEW_TITLE,
  CAVC_REMAND_REVIEW_SUBHEAD,
  CAVC_REMAND_REVIEW_ABOUT_APPELLANT_LABEL,
  CAVC_REMAND_REVIEW_TASKS_CANCEL_LABEL,
  CAVC_REMAND_REVIEW_TASKS_REACTIVATE_LABEL,
} from 'app/../COPY';
import CheckoutButtons from 'app/queue/docketSwitch/grant/CheckoutButtons';
import { pageHeader } from '../styles';
import { format, parseISO } from 'date-fns';
import { css } from 'glamor';

const styles = {
  mainTable: css({
    '& .bolded-header': {
      fontWeight: 'bold',
    },
    '& tr > td': {
      width: '50%',
    },
    '&': {
      margin: 0,
    },
    '& tr:first-of-type td': {
      borderTop: '1px solid #D6D7D9',
    },
    '& tr:last-of-type td': {
      paddingBottom: '20px',
    },
  }),
  tableSection: css({
    marginBottom: '40px'
  })
};

export const EditCavcRemandReview = ({
  appeal,
  tasksToCancel,
  tasksToReActivate,
  existingValues,
  relationship,
  onBack,
  onCancel,
  onSubmit,
}) => {
  return (
    <>
      <AppSegment filledBackground>
        <section className={pageHeader}>
          <h1>{CAVC_REMAND_REVIEW_TITLE}</h1>
          <div>{CAVC_REMAND_REVIEW_SUBHEAD}</div>
        </section>
        <section className={styles.tableSection}>
          <h2>{CAVC_REMAND_REVIEW_ABOUT_APPELLANT_LABEL}</h2>
          <table className={`usa-table-borderless ${styles.mainTable}`}>
            <tbody>
              { existingValues.isAppellantSubstituted === 'true' && (
                <>
                  <tr>
                    <td className="appellant-detail">
                      Substitution granted by the RO
                    </td>
                    <td>
                      {existingValues.substitutionDate &&
                       format(parseISO(existingValues.substitutionDate), 'MM/dd/yyyy')}
                    </td>
                  </tr>
                </>
              )}
              <tr>
                <td className="appellant-detail">Name</td>
                <td>
                  {existingValues.isAppellantSubstituted === 'true' ?
                    relationship && relationship.fullName : appeal.veteranFullName}
                </td>
              </tr>
              <tr>
                <td className="appellant-detail">Relation to Veteran</td>
                <td>
                  {existingValues.isAppellantSubstituted === 'true' ?
                    relationship && relationship.relationshipType : 'Veteran'}
                </td>
              </tr>
            </tbody>
          </table>
        </section>
        {tasksToCancel.length > 0 && (
          <section className={styles.tableSection}>
            <h2>{CAVC_REMAND_REVIEW_TASKS_CANCEL_LABEL}</h2>
            <table className={`usa-table-borderless ${styles.mainTable}`}>
              <tbody>
                {tasksToCancel.map((task) => {
                  return (
                    <tr className="task-detail" key={`${task.taskId}`}>
                      <td>
                        {task.label.replace('Task', '')}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </section>
        )}
        { tasksToReActivate.length > 0 && (
          <section className={styles.tableSection}>
            <h2>{CAVC_REMAND_REVIEW_TASKS_REACTIVATE_LABEL}</h2>
            <table className={`usa-table-borderless ${styles.mainTable}`}>
              <tbody>
                {tasksToReActivate.map((task) => {
                  return (
                    <tr className="task-detail" key={`${task.taskId}`}>
                      <td>
                        {task.label.replace('Task', '')}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </section>
        )}
      </AppSegment>
      <div className="controls cf-app-segment">
        <CheckoutButtons
          onCancel={onCancel}
          onBack={onBack}
          onSubmit={onSubmit}
          submitText="Confirm"
        />
      </div>
    </>
  );
};
EditCavcRemandReview.propTypes = {
  tasksToMaintain: PropTypes.arrayOf(
    PropTypes.shape({
      taskId: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
      label: PropTypes.string,
    })
  ),
  tasksToCancel: PropTypes.arrayOf(
    PropTypes.shape({
      taskId: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
      label: PropTypes.string,
    })
  ),
  taskstoReactivate: PropTypes.arrayOf(
    PropTypes.shape({
      taskId: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
      label: PropTypes.string,
    })
  ),
  existingValues: PropTypes.shape({
    substitutionDate: PropTypes.string,
    participantId: PropTypes.string,
    taskIds: PropTypes.array,
    isAppellantSubstituted: PropTypes.string
  }),
  evidenceSubmissionEndDate: PropTypes.string,
  relationship: PropTypes.shape({
    fullName: PropTypes.string,
    relationshipType: PropTypes.string,
  }),
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  appeal: PropTypes.object,
};
