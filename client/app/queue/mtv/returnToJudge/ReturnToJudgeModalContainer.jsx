import React from 'react';
import { useHistory, useParams } from 'react-router';
import { ReturnToJudgeModal } from './ReturnToJudgeModal';
import { useDispatch, useSelector } from 'react-redux';
import ApiUtil from '../../../util/ApiUtil';
import { showSuccessMessage } from '../../uiReducer/uiActions';
import { returnToJudgeAlert } from '../mtvMessages';
import { appealWithDetailSelector, taskById } from '../../selectors';

export const ReturnToJudgeModalContainer = () => {
  const { goBack, push } = useHistory();
  const { taskId, appealId } = useParams();
  const appeal = useSelector((state) => appealWithDetailSelector(state, { appealId }));
  const dispatch = useDispatch();

  const handleSubmit = async ({ instructions }) => {
    const url = '/post_decision_motions/return_to_judge';
    const data = ApiUtil.convertToSnakeCase({
      taskId,
      instructions
    });

    try {
      const { body } = await ApiUtil.post(url, { data });
      const judge = body?.task?.data?.attributes?.assigned_to;

      dispatch(
        showSuccessMessage(
          returnToJudgeAlert({
            appeal,
            judge
          })
        )
      );

      push('/queue');
    } catch (error) {
      console.error('Error during returnToJudge', error);
    }
  };

  return <ReturnToJudgeModal onCancel={goBack} onSubmit={handleSubmit} />;
};
