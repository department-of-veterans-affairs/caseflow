import React from 'react';
import PropTypes from 'prop-types';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  SUBSTITUTE_APPELLANT_REVIEW_TITLE,
  SUBSTITUTE_APPELLANT_REVIEW_SUBHEAD,
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
      borderBottom: 'none',
      paddingBottom: '20px',
    },
  }),
};

export const SubstituteAppellantReview = ({
  selectedTasks,
  existingValues,
  evidenceSubmissionEndDate,
  relationship,
  onBack,
  onCancel,
  onSubmit,
}) => {
  const substitutionDate = format(
    parseISO(existingValues.substitutionDate),
    'MM/dd/yyyy'
  );

  return (
    <>
      <AppSegment filledBackground>
        <section className={pageHeader}>
          <h1>{SUBSTITUTE_APPELLANT_REVIEW_TITLE}</h1>
          <div>{SUBSTITUTE_APPELLANT_REVIEW_SUBHEAD}</div>
        </section>
        <section>
          <h2>About the appellant</h2>
          <table className={`usa-table-borderless ${styles.mainTable}`}>
            <tbody>
              <tr>
                <td className="bolded-header">
                  Substitution granted by the RO
                </td>
                <td>{existingValues.substitutionDate && substitutionDate}</td>
              </tr>
              <tr>
                <td className="bolded-header">Name</td>
                <td>{relationship && relationship.fullName}</td>
              </tr>
              <tr>
                <td className="bolded-header">Relation to Veteran</td>
                <td>{relationship && relationship.relationshipType}</td>
              </tr>
            </tbody>
          </table>
        </section>
        <section>
          <h2>Reactivated tasks</h2>
          {selectedTasks.length > 0 && (
            <table className={`usa-table-borderless ${styles.mainTable}`}>
              <tbody>
                {selectedTasks.map((task) => {
                  return (
                    <tr className="task-detail" key={`${task.taskId}`}>
                      <td>
                        {task.label.
                          split(' ').
                          slice(0, -1).
                          join(' ')}
                      </td>
                      <td>
                        {task.type === 'EvidenceSubmissionWindowTask' && (
                          <span className="bolded-header">End date: </span>
                        )}
                        {task.type === 'EvidenceSubmissionWindowTask' &&
                          format(evidenceSubmissionEndDate, 'MM/dd/yyyy')}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </section>
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
SubstituteAppellantReview.propTypes = {
  selectedTasks: PropTypes.arrayOf(
    PropTypes.shape({
      taskId: PropTypes.number,
      label: PropTypes.string,
    })
  ),
  existingValues: PropTypes.shape({
    substitutionDate: PropTypes.string,
    participantId: PropTypes.string,
    taskIds: PropTypes.array,
  }),
  evidenceSubmissionEndDate: PropTypes.instanceOf(Date),
  relationship: PropTypes.shape({
    fullName: PropTypes.string,
    relationshipType: PropTypes.string,
  }),
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
};
