import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';
import { format } from 'date-fns';
import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import StringUtil from 'app/util/StringUtil';
import {
  DOCKET_SWITCH_GRANTED_CONFIRM_TITLE,
  DOCKET_SWITCH_GRANTED_CONFIRM_DESCRIPTION_A,
  DOCKET_SWITCH_GRANTED_CONFIRM_DESCRIPTION_B,
} from 'app/../COPY';
import CheckoutButtons from './CheckoutButtons';

const styles = {
  mainTable: css({
    '& > tbody > tr > td': {
      verticalAlign: 'top',
      ':first-child': {
        fontWeight: 'bold',
      },
    },
    '& table': {
      margin: 0,
      '& tr:first-of-type td': {
        borderTop: 'none',
      },
      '& tr:last-of-type td': {
        borderBottom: 'none',
      },
    },
  }),
};

export const DocketSwitchReviewConfirm = ({
  claimantName,
  docketFrom,
  docketTo,
  onCancel,
  onBack,
  onSubmit,
  loading = false,
  originalReceiptDate,
  docketSwitchReceiptDate,
  issuesSwitched,
  issuesRemaining,
  tasksKept,
  tasksAdded = [],
  veteranName,
}) => {
  const description1 = useMemo(
    () =>
      sprintf(
        DOCKET_SWITCH_GRANTED_CONFIRM_DESCRIPTION_A,
        StringUtil.snakeCaseToCapitalized(docketFrom),
        StringUtil.snakeCaseToCapitalized(docketTo),
        StringUtil.snakeCaseToCapitalized(docketFrom),
        StringUtil.snakeCaseToCapitalized(docketTo)
      ),
    [docketFrom, docketTo]
  );

  const noTasksShown = () => {
    if (![...tasksKept, ...tasksAdded]?.length) {
      return 'None';
    }
  };

  return (
    <>
      <AppSegment filledBackground>
        <h1>{DOCKET_SWITCH_GRANTED_CONFIRM_TITLE}</h1>
        <p>
          <strong>{description1}</strong>
        </p>
        <p>{DOCKET_SWITCH_GRANTED_CONFIRM_DESCRIPTION_B}</p>

        <table className={`usa-table-borderless ${styles.mainTable}`}>
          <tbody>
            <tr>
              <td>Veteran</td>
              <td>{veteranName}</td>
            </tr>
            {claimantName && (
              <tr>
                <td>Claimant</td>
                <td>{claimantName}</td>
              </tr>
            )}
            <tr>
              <td>VA Form - 10182 Receipt Date</td>
              <td>{format(originalReceiptDate, 'M/d/y')}</td>
            </tr>
            <tr>
              <td>Docket Switch Receipt Date</td>
              <td>{format(docketSwitchReceiptDate, 'M/d/y')}</td>
            </tr>
            <tr>
              <td>New Review option</td>
              <td>{StringUtil.snakeCaseToCapitalized(docketTo)}</td>
            </tr>
            <tr>
              <td>Issues switched to new docket</td>
              <td>
                <table className="usa-table-borderless">
                  <tbody>
                    {issuesSwitched.map((issue, idx) => (
                      <tr key={issue.id}>
                        <td>
                          <div>{`${idx + 1}. ${issue.description}`}</div>
                          <div>
                            Decision date:{' '}
                            {format(Date.parse(issue.decision_date), 'M/d/Y')}
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </td>
            </tr>
            {Boolean(issuesRemaining?.length) && (
              <tr>
                <td>Issues on original docket</td>
                <td>
                  <table className="usa-table-borderless">
                    <tbody>
                      {issuesRemaining.map((issue, idx) => (
                        <tr key={issue.id}>
                          <td>
                            <div>{`${idx + 1}. ${issue.description}`}</div>
                            <div>
                              Decision date:{' '}
                              {format(Date.parse(issue.decision_date), 'M/d/Y')}
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </td>
              </tr>
            )}
            <tr>
              <td>Transferred/Added tasks</td>
              <td>
                <table className="usa-table-borderless">
                  <tbody>
                    <tr>
                      <td>
                        <div>
                          <em>{noTasksShown()}</em>
                        </div>
                      </td>
                    </tr>
                    {[...tasksKept, ...tasksAdded].map((task, idx) => (
                      <tr key={task.id || task.name}>
                        <td>
                          <div>{`${idx + 1}. ${task.label}`}</div>
                          <div>
                            <em>{task.instructions}</em>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </td>
            </tr>
          </tbody>
        </table>
      </AppSegment>
      <div className="controls cf-app-segment">
        <CheckoutButtons
          onCancel={onCancel}
          onBack={onBack}
          onSubmit={onSubmit}
          loading={loading}
          submitText="Confirm docket switch"
        />
      </div>
    </>
  );
};
DocketSwitchReviewConfirm.propTypes = {
  veteranName: PropTypes.string,
  claimantName: PropTypes.string,
  docketFrom: PropTypes.string,
  docketTo: PropTypes.string,
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  loading: PropTypes.bool,
  originalReceiptDate: PropTypes.instanceOf(Date),
  docketSwitchReceiptDate: PropTypes.instanceOf(Date),
  issuesSwitched: PropTypes.arrayOf(
    PropTypes.shape({
      label: PropTypes.string,
      date: PropTypes.string,
    })
  ),
  issuesRemaining: PropTypes.arrayOf(
    PropTypes.shape({
      label: PropTypes.string,
      date: PropTypes.string,
    })
  ),
  tasksKept: PropTypes.arrayOf(
    PropTypes.shape({
      label: PropTypes.string,
      instructions: PropTypes.string,
    })
  ),
  tasksAdded: PropTypes.arrayOf(
    PropTypes.shape({
      label: PropTypes.string,
      instructions: PropTypes.string,
    })
  ),
};
