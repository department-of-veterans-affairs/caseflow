import React, { useMemo } from 'react';

import { useDispatch, useSelector } from 'react-redux';
import { useHistory, useParams } from 'react-router';
import StringUtil from 'app/util/StringUtil';
import { appealWithDetailSelector } from 'app/queue/selectors';
import { DocketSwitchReviewConfirm } from './DocketSwitchReviewConfirm';
import { cancel } from '../docketSwitchSlice';

export const DocketSwitchReviewConfirmContainer = () => {
  const { appealId } = useParams();
  const { goBack, push } = useHistory();
  const dispatch = useDispatch();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const formData = useSelector((state) => state.docketSwitch.formData);

  const handleCancel = () => {
    // Clear Redux store
    dispatch(cancel());

    // Return to case details page
    push(`/queue/appeals/${appealId}`);
  };

  const handleSubmit = () => console.log('submit');

  //   We need to display more info than just the stored issue IDs
  const [issuesSwitched, issuesRemaining] = useMemo(() => {
    return appeal.issues.reduce(
      (issueArr, issue) => {
        issueArr[formData.issueIds.includes(issue.id) ? 0 : 1].push(issue);

        return issueArr;
      },
      [[], []]
    );
  }, [formData]);

  return (
    <DocketSwitchReviewConfirm
      claimantName={appeal.claimantName}
      docketFrom={StringUtil.snakeCaseToCapitalized(appeal.docketName)}
      docketTo={StringUtil.snakeCaseToCapitalized(formData.docketType)}
      issuesSwitched={issuesSwitched}
      issuesRemaining={issuesRemaining}
      onBack={goBack}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
    />
  );
};
