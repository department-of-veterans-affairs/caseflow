// @flow
import moment from 'moment';
import type { Task } from '../types/models';

export const numDaysOnHold = (task: Task) => moment().startOf('day').
  diff(task.placedOnHoldAt, 'days');

type Props = { task: Task };
const OnHoldLabel = (props: Props) => `${numDaysOnHold(props.task)} of ${props.task.onHoldDuration || '?'}`;

export default OnHoldLabel;
