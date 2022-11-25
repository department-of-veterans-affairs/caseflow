import Moment from 'moment';
import { extendMoment } from 'moment-range';

const moment = extendMoment(Moment);

const isSameRange = (rangeA, rangeB) => {
  return rangeA.start.isSame(rangeB.start, 'day') && rangeA.end.isSame(rangeB.end, 'day');
};

export const calculateDaysWorked = (tasks, daysAssigned) => {
  let sumOfDays = 0;

  // Map all tasks' createdAt to closedAt to a moment.range object
  const dateRanges = tasks.map((task) => moment.range(moment(task.createdAt), moment(task.closedAt)));

  const uniqueDateRanges = [];
  const alreadyAccountedForDateRanges = [];

  // For all tasks' date ranges find overlapping date ranges
  dateRanges.forEach((dateRange) => {

    // If a date range was already found to be overlapping do not create another combined overlapping date range
    if (alreadyAccountedForDateRanges.findIndex((range) => isSameRange(dateRange, range)) < 0) {

      // Find all overlapping date ranges
      const overlappingDateRanges = dateRanges.filter((range) => dateRange.overlaps(range, { adjacent: true }));

      // Track used date ranges so they are not used again
      alreadyAccountedForDateRanges.push(...overlappingDateRanges);

      // Add all overlapping date ranges together
      let overlappingDateRange = dateRange.clone();

      overlappingDateRanges.forEach((range) => {
        overlappingDateRange = overlappingDateRange.add(range, { adjacent: true });
      });

      uniqueDateRanges.push(overlappingDateRange);
    }
  });

  uniqueDateRanges.forEach((range) => {
    sumOfDays += Math.max(1, range.diff('days'));
  });

  return daysAssigned - Math.max(1, sumOfDays) - 1;
};
