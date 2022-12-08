import Moment from 'moment';
import { extendMoment } from 'moment-range';
import { compareDesc } from 'date-fns';

const moment = extendMoment(Moment);

const isSameRange = (rangeA, rangeB) => {
  return rangeA.start.isSame(rangeB.start, 'day') && rangeA.end.isSame(rangeB.end, 'day');
};

const findSumOfUniqueDateRanges = (dateRanges) => {
  let sumOfDays = 0;

  const uniqueDateRanges = [];
  const alreadyAccountedForDateRanges = [];

  // For provided date ranges find overlapping date ranges
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

  return Math.max(0, sumOfDays);
};

const findSumOfJudgeDays = (attorneyTasks) => {
  // Build date rangs based on pairs of tasks
  // This list comes in sorted so oldest task has 0 index
  // Build a date range like moment.range(attorneyTask[0].closedAt, attorneyTask[1].createdAt)
  // These date ranges are the gaps when a Case was returned back to the Judge
  const judgeGapDateRanges = attorneyTasks.map((task, index) => {
    if (index + 1 < attorneyTasks.length) {
      const nextTask = attorneyTasks[index + 1];

      return moment.range(moment(task.closedAt), moment(nextTask.createdAt));
    }

    return null;
  }).filter((range) => range !== null);

  return findSumOfUniqueDateRanges(judgeGapDateRanges);
};

export const calculateDaysWorked = (allChildrenTasks, daysAssigned, attorneyTasks) => {
  // Map all Attorney task children tasks createdAt to closedAt to a moment.range object
  const allTasksUniqueDateRanges = allChildrenTasks.map((task) =>
    moment.range(moment(task.createdAt), moment(task.closedAt))
  );

  let sumOfAllChildrenTasksDays = 0;

  if (allChildrenTasks.length > 0) {
    sumOfAllChildrenTasksDays = Math.max(1, findSumOfUniqueDateRanges(allTasksUniqueDateRanges));
  }

  let sumOfJudgeDays = 0;

  if (attorneyTasks.length > 0) {
    sumOfJudgeDays = findSumOfJudgeDays(attorneyTasks);
  }

  const daysWorked = daysAssigned - sumOfAllChildrenTasksDays - sumOfJudgeDays - 1;

  return Math.max(0, daysWorked);
};

export const determineLocationHistories = (locationHistories, timelinessRange) => {

  // filter out locations outside of the timeliness range and with an attorney
  // See app/models/vacols/priorloc.rb#with_attorney?
  const notWithAttorneyLocations = locationHistories.
    filter((location) =>
      !location.withAttorney && timelinessRange.contains(moment(location.createdAt))
    );

  // sort by createdAt since that is locdout
  notWithAttorneyLocations.sort((prev, next) => compareDesc(new Date(prev.createdAt), new Date(next.createdAt)));

  // Set location's closedAt based on pairs of locations using locdout values
  // This is the best way to determine date ranges of when a record was at a location
  // This is recommended path by VACOLS SME
  //
  // Ex: location[0]'s closedAt becomes location[1].createdAt
  //
  const remappedLocationHistories = notWithAttorneyLocations.map((location, index) => {
    if (index + 1 < notWithAttorneyLocations.length) {
      const nextLocation = notWithAttorneyLocations[index + 1];

      return {
        ...location,
        closedAt: nextLocation.createdAt,
      };
    }

    return location;
  }).filter((location) => location.closedAt !== null);

  return remappedLocationHistories;
};
