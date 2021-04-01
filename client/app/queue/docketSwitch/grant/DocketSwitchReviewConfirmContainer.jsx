import React, { useMemo, useState } from 'react';

import { useDispatch, useSelector } from 'react-redux';
import { useHistory, useParams } from 'react-router';
import { unwrapResult } from '@reduxjs/toolkit';
import { parseISO } from 'date-fns';
import StringUtil from 'app/util/StringUtil';
import { appealWithDetailSelector } from 'app/queue/selectors';
import colocatedAdminActions from 'constants/CO_LOCATED_ADMIN_ACTIONS';
import { DocketSwitchReviewConfirm } from './DocketSwitchReviewConfirm';
import { cancel, completeDocketSwitchGranted, stepForward } from '../docketSwitchSlice';
import { showSuccessMessage } from '../../uiReducer/uiActions';
import { sprintf } from 'sprintf-js';
import {
  DOCKET_SWITCH_PARTIAL_GRANTED_SUCCESS_TITLE,
  DOCKET_SWITCH_FULL_GRANTED_SUCCESS_TITLE,
  DOCKET_SWITCH_GRANTED_SUCCESS_MESSAGE
} from 'app/../COPY';

export const reformatTaskType = (type) => {
  const truncated = type.replace('ColocatedTask', '');
  const camel = truncated.charAt(0).toLowerCase() + truncated.slice(1);

  return StringUtil.camelCaseToSnakeCase(camel);
};

export const DocketSwitchReviewConfirmContainer = () => {
  const { appealId, taskId } = useParams();
  const { goBack, push } = useHistory();
  const dispatch = useDispatch();
  const [loading, setLoading] = useState(false);

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const amaTasks = useSelector((state) => state.queue.amaTasks);

  const formData = useSelector((state) => state.docketSwitch.formData);

  const receiptDate = useMemo(() => parseISO(appeal.nodDate), [appeal.nodDate]);

  const docketType = useSelector(
    (state) => state.docketSwitch.formData.docketType
  );

  const dispositionType = useSelector(
    (state) => state.docketSwitch.formData.disposition
  );

  const handleCancel = () => {
    // Clear Redux store
    dispatch(cancel());

    // Return to case details page
    push(`/queue/appeals/${appealId}`);
  };

  const handleSubmit = async () => {
    // Make API call, redirect, etc

    const partialGrantedMessage = {
      title: sprintf(DOCKET_SWITCH_PARTIAL_GRANTED_SUCCESS_TITLE,
        appeal.appellantFullName, StringUtil.snakeCaseToCapitalized(docketType)),
      detail: DOCKET_SWITCH_GRANTED_SUCCESS_MESSAGE,
    };

    const fullGrantedMessage = {
      title: sprintf(DOCKET_SWITCH_FULL_GRANTED_SUCCESS_TITLE,
        appeal.appellantFullName, StringUtil.snakeCaseToCapitalized(docketType)),
      detail: DOCKET_SWITCH_GRANTED_SUCCESS_MESSAGE,
    };

    const successMessage = dispositionType === 'partially_granted' ? partialGrantedMessage : fullGrantedMessage;

    const docketSwitch = {
      disposition: formData.disposition,
      receipt_date: formData.receiptDate,
      docket_type: formData.docketType,
      granted_request_issue_ids: formData.issueIds,
      new_admin_actions: formData.newTasks,
      selected_task_ids: formData.taskIds,
      task_id: taskId,
      old_docket_stream_id: appeal.id
    };

    try {
      setLoading(true);
      const resultAction = await dispatch(completeDocketSwitchGranted(docketSwitch));
      const { newAppealId } = unwrapResult(resultAction);

      dispatch(showSuccessMessage(successMessage));
      dispatch(stepForward());
      push(`/queue/appeals/${newAppealId}`);
    } catch (error) {
      // Perhaps show an alert that indicates error, advise trying again...?
      console.error('Error Granting Docket Switch', error);
    }

  };

  //   We need to display more info than just the stored issue IDs
  const [issuesSwitched, issuesRemaining] = useMemo(() => {
    return appeal.issues.reduce(
      (issueArr, issue) => {
        issueArr[formData.issueIds.includes(String(issue.id)) ? 0 : 1].push(issue);

        return issueArr;
      },
      [[], []]
    );
  }, [formData]);

  const tasksSwitched = useMemo(() => {
    return formData.taskIds.map((taskid) => amaTasks[taskid]);
  }, [formData.taskIds, amaTasks]);

  const tasksAdded = useMemo(() => {
    if (formData.newTasks) {
      return formData.newTasks.map(({ type, instructions }) => {
        const label = colocatedAdminActions[reformatTaskType(type)];

        return { type, label, instructions };
      });
    }
  }, [formData.newTasks, colocatedAdminActions]);

  return (
    <DocketSwitchReviewConfirm
      claimantName={appeal.claimantName}
      docketFrom={StringUtil.snakeCaseToCapitalized(appeal.docketName)}
      docketTo={StringUtil.snakeCaseToCapitalized(formData.docketType)}
      docketSwitchReceiptDate={parseISO(formData.receiptDate)}
      issuesSwitched={issuesSwitched}
      issuesRemaining={issuesRemaining}
      onBack={goBack}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
      loading={loading}
      originalReceiptDate={receiptDate}
      tasksAdded={tasksAdded}
      tasksKept={tasksSwitched}
      veteranName={appeal.veteranFullName}
    />
  );
};
