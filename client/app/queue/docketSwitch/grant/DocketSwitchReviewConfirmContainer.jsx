import React, { useMemo } from 'react';

import { useDispatch, useSelector } from 'react-redux';
import { useHistory, useParams } from 'react-router';
import { parseISO } from 'date-fns';
import StringUtil from 'app/util/StringUtil';
import { appealWithDetailSelector } from 'app/queue/selectors';
import colocatedAdminActions from 'constants/CO_LOCATED_ADMIN_ACTIONS';
import { DocketSwitchReviewConfirm } from './DocketSwitchReviewConfirm';
import { cancel } from '../docketSwitchSlice';

export const reformatTaskType = (type) => {
  const truncated = type.replace('ColocatedTask', '');
  const camel = truncated.charAt(0).toLowerCase() + truncated.slice(1);

  return StringUtil.camelCaseToSnakeCase(camel);
};

export const DocketSwitchReviewConfirmContainer = () => {
  const { appealId } = useParams();
  const { goBack, push } = useHistory();
  const dispatch = useDispatch();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const amaTasks = useSelector((state) => state.queue.amaTasks);

  const formData = useSelector((state) => state.docketSwitch.formData);

  const receiptDate = useMemo(() => parseISO(appeal.nodDate), [appeal.nodDate]);

  const handleCancel = () => {
    // Clear Redux store
    dispatch(cancel());

    // Return to case details page
    push(`/queue/appeals/${appealId}`);
  };

  const handleSubmit = () => {
    // Make API call, redirect, etc
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
    return formData.taskIds.map((taskId) => amaTasks[taskId]);
  }, [formData.taskIds, amaTasks]);

  const tasksAdded = useMemo(() => {
    return formData.newTasks.map(({ type, instructions }) => {
      const label = colocatedAdminActions[reformatTaskType(type)];

      return { type, label, instructions };
    });
  }, [formData.newTasks, colocatedAdminActions]);

  return (
    <DocketSwitchReviewConfirm
      claimantName={appeal.claimantName}
      docketFrom={StringUtil.snakeCaseToCapitalized(appeal.docketName)}
      docketTo={StringUtil.snakeCaseToCapitalized(formData.docketType)}
      docketSwitchReceiptDate={new Date(formData.receiptDate)}
      issuesSwitched={issuesSwitched}
      issuesRemaining={issuesRemaining}
      onBack={goBack}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
      originalReceiptDate={receiptDate}
      tasksAdded={tasksAdded}
      tasksKept={tasksSwitched}
      veteranName={appeal.veteranFullName}
    />
  );
};
