import moment from 'moment';

export const numDaysOnHold = (task) => moment().startOf('day').
  diff(task.placedOnHoldAt, 'days');

const OnHoldLabel = (props) => `${numDaysOnHold(props.task)}${props.task.onHoldDuration ? ` of ${
  props.task.onHoldDuration}` : ''}`;

export default OnHoldLabel;
