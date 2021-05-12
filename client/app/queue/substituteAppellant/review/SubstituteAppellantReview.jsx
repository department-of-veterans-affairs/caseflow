import React from 'react';
import { useSelector } from 'react-redux';
import PropTypes from 'prop-types';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  SUBSTITUTE_APPELLANT_REVIEW_TITLE,
  SUBSTITUTE_APPELLANT_REVIEW_SUBHEAD,
} from 'app/../COPY';
import CheckoutButtons from 'app/queue/docketSwitch/grant/CheckoutButtons';
import { pageHeader } from '../styles';
import { css } from 'glamor';
import { format, parseISO } from 'date-fns';

const styles = {
  mainTable: css({
    '&': {
      margin: 0,
      '& tr:last-of-type td': {
        borderBottom: 'none',
      },
    },
  }),
};

export const SubstituteAppellantReview = ({ selectedTasks, existingValues, evidenceSubmissionEndDate, onBack, onCancel, onSubmit }) => {

  const substitutionDate = format(parseISO(existingValues.substitutionDate), 'MM/dd/yyyy');
  const { relationships } = useSelector((state) => state.substituteAppellant);
  const relationship = relationships.find((rel) => rel.value === existingValues.participantId);

  return (
    <>
      <AppSegment filledBackground>
        <section className={pageHeader}>
          <h1>{SUBSTITUTE_APPELLANT_REVIEW_TITLE}</h1>
          <div>{SUBSTITUTE_APPELLANT_REVIEW_SUBHEAD}</div>
        </section>
        <section>
          <h1>About the appellant</h1>
          <table className={`usa-table-borderless ${styles.mainTable}`}>
            <tbody>
              <tr>
                <td>
                  Substitution granted by the RO
                </td>
                <td>
                  { existingValues.substitutionDate && substitutionDate }
                </td>
              </tr>
              <tr>
                <td>
                  Name
                </td>
                <td>
                  { relationship && relationship.fullName }
                </td>
              </tr>
              <tr>
                <td>
                  Relation to Veteran
                </td>
                <td>
                  { relationship && relationship.relationshipType }
                </td>
              </tr>
            </tbody>
          </table>
        </section>
        <section>
          <h1>Reactivated tasks</h1>
          {selectedTasks.length > 0 && <table className={`usa-table-borderless ${styles.mainTable}`}>
            <tbody>
              { selectedTasks.map((task) => {
                return <tr className="task-detail" key={`${task.taskId}`}>
                  <td>
                    { task.label.split(' ').slice(0, -1).
                      join(' ') }
                  </td>
                  { task.type === 'EvidenceSubmissionWindowTask' && <td>
                    End date: { format(evidenceSubmissionEndDate, 'MM/dd/yyyy') }
                  </td> }
                </tr>;
              }
              )}
            </tbody>
          </table>}
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
  selectedTasks: PropTypes.arrayOf(PropTypes.shape({
    taskId: PropTypes.number,
    label: PropTypes.string,
  })),
  existingValues: PropTypes.shape({
    substitutionDate: PropTypes.string,
    participantId: PropTypes.string,
    taskIds: PropTypes.array,
  }),
  evidenceSubmissionEndDate: PropTypes.instanceOf(Date),
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
};
