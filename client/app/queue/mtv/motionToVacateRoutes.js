import React from 'react';
import { Route, useParams, useHistory } from 'react-router';
import PageRoute from '../../components/PageRoute';

import TASK_ACTIONS from '../../../constants/TASK_ACTIONS.json';
import { ReviewMotionToVacateView } from './ReviewMotionToVacateView';
import { AddressMotionToVacateView } from './AddressMotionToVacateView';
import { ReturnToLitSupportModal } from './ReturnToLitSupportModal';
import { useDispatch } from 'react-redux';
import { returnToLitSupport } from './mtvActions';

const RoutedReturnToLitSupport = (props) => {
  const { taskId } = useParams();
  const { goBack } = useHistory();
  const dispatch = useDispatch();

  return (
    <ReturnToLitSupportModal
      onCancel={() => goBack()}
      onSubmit={({ instructions }) => dispatch(returnToLitSupport({ instructions,
        task_id: taskId }, props))}
    />
  );
};

const PageRoutes = [
  <PageRoute
    path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ADDRESS_MOTION_TO_VACATE.value}`}
    title="Address Motion to Vacate | Caseflow"
    component={AddressMotionToVacateView}
  />
];

const ModalRoutes = [
  <PageRoute
    exact
    path={[
      '/queue/appeals/:appealId/tasks/:taskId',
      TASK_ACTIONS.ADDRESS_MOTION_TO_VACATE.value,
      TASK_ACTIONS.JUDGE_RETURN_TO_LIT_SUPPORT.value
    ].join('/')}
    title="Return to Litigation Support | Caseflow"
    component={RoutedReturnToLitSupport}
  />,
  <Route
    path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.SEND_MOTION_TO_VACATE_TO_JUDGE.value}`}
    component={ReviewMotionToVacateView}
  />
];

export const motionToVacateRoutes = {
  page: PageRoutes,
  modal: ModalRoutes
};
