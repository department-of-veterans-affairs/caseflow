import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import StringUtil from 'app/util/StringUtil';
import {
  DOCKET_SWITCH_GRANTED_CONFIRM_TITLE,
  DOCKET_SWITCH_GRANTED_CONFIRM_DESCRIPTION_A,
  DOCKET_SWITCH_GRANTED_CONFIRM_DESCRIPTION_B,
} from 'app/../COPY';
import CheckoutButtons from './CheckoutButtons';

export const DocketSwitchReviewConfirm = ({
  claimantName,
  docketFrom,
  docketTo,
  onCancel,
  onBack,
  onSubmit,
  originalReceiptDate,
  docketSwitchReceiptDate,
  issuesSwitched,
  issuesRemaining,
  tasksKept,
  tasksAdded,
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

  return (
    <>
      <AppSegment filledBackground>
        <h1>{DOCKET_SWITCH_GRANTED_CONFIRM_TITLE}</h1>
        <p>
          <strong>{description1}</strong>
        </p>
        <p>{DOCKET_SWITCH_GRANTED_CONFIRM_DESCRIPTION_B}</p>

        <table className="usa-table-borderless">
          <tbody>
            <tr>
              <td>Veteran</td>
              <td>{claimantName}</td>
            </tr>
            <tr>
              <td>VA Form - 10182 Receipt Date</td>
              <td>{originalReceiptDate}</td>
            </tr>
            <tr>
              <td>Docket Switch Receipt Date</td>
              <td>{docketSwitchReceiptDate}</td>
            </tr>
            <tr>
              <td>New Review option</td>
              <td>{StringUtil.snakeCaseToCapitalized(docketTo)}</td>
            </tr>
          </tbody>
        </table>
      </AppSegment>
      <div className="controls cf-app-segment">
        <CheckoutButtons
          onCancel={onCancel}
          onBack={onBack}
          onSubmit={onSubmit}
        />
      </div>
    </>
  );
};
DocketSwitchReviewConfirm.propTypes = {
  claimantName: PropTypes.string,
  docketFrom: PropTypes.string,
  docketTo: PropTypes.string,
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  originalReceiptDate: PropTypes.string,
  docketSwitchReceiptDate: PropTypes.string,
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
