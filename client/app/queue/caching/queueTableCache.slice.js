import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  cachedResponses: {},
};

const generateKeyFromUrl = (urlString) => {
  // Split the url to only have get params
  const params = new URLSearchParams(urlString.split('?')[1]);
  const filter = params.get('filter');
  const tab = params.get('tab');

  // Create a group key based on filter and tab values
  const groupKey = `filter=${filter}&tab=${tab}`;

  return groupKey;
};

// TODO: Can maybe group the two forEach loops even though it's gross
const groupUrlKeysByParams = (urlKeys) => {
  const groups = {};

  Object.keys(urlKeys).forEach((urlString) => {
    // const url = new URL(urlString);
    // const params = new URLSearchParams(url.search);
    // const params = new URLSearchParams(urlString.split('?')[1]);
    // const filter = params.get('filter');
    // const tab = params.get('tab');

    // console.log('in my groupUrlKeysByParams function for key:', urlString);

    // Create a group key based on filter and tab values
    // const groupKey = `filter=${filter}&tab=${tab}`;

    const groupKey = generateKeyFromUrl(urlString);

    // Initialize the group if it doesn't exist
    if (!groups[groupKey]) {
      groups[groupKey] = {
        urls: [],
        count: 0
      };
    }

    // console.log('does it get past this point then??:', groupKey);

    // Add the URL key to the corresponding group
    // groups[groupKey].push(urlString);
    groups[groupKey].urls.push(urlString);
    // console.log('does it die when trying to add the key to the object??');
  });

  return groups;
};

const addToUrlCount = (groupedUrls, urlString, number) => {
  // const url = new URL(urlString);
  // const params = new URLSearchParams(url.search);
  // const params = new URLSearchParams(urlString.split('?')[1]);
  // const filter = params.get('filter');
  // const tab = params.get('tab');

  // const groupKey = `filter=${filter}&tab=${tab}`;

  const groupKey = generateKeyFromUrl(urlString);

  if (groupedUrls[groupKey]) {
    groupedUrls[groupKey].count += number;
  }
};

const createUrlCountObject = (groupedUrls) => {
  const urlCountObject = {};

  Object.values(groupedUrls).forEach((group) => {
    group.urls.forEach((urlString) => {
      urlCountObject[urlString] = group.count;
    });
  });

  return urlCountObject;
};

const calculatePages = (itemsPerPage, totalItems) => {
  return Math.ceil(totalItems / itemsPerPage);
};

const resetState = () => ({ ...initialState });

const queueTableCacheSlice = createSlice({
  name: 'queueTableCache',
  initialState,
  reducers: {
    reset: resetState,
    updateQueueTableCache: (state, action) => {
      const { key, value } = action.payload;

      state.cachedResponses[key] = value;
    },
    removeTaskIdsFromCache: (state, action) => {
      const { taskIds } = action.payload;

      // console.log('in my new reducer with taskIds:', taskIds);

      const groupedKeys = groupUrlKeysByParams(state.cachedResponses);

      // console.log(groupedKeys);

      Object.keys(state.cachedResponses).forEach((key) => {
        const cachedResponse = state.cachedResponses[key];
        // const taskCount = cachedResponse.total_task_count;

        // console.log('total task count before action: ', taskCount);

        if (cachedResponse.tasks && Array.isArray(cachedResponse.tasks)) {

          // URLSearchParams
          // const originalTaskCount = cachedResponse.tasks.length;
          // console.log('in my action??');

          // console.log('my original tasks:', cachedResponse);

          const filteredTasks = cachedResponse.tasks.filter((task) => !taskIds.includes(task.id));

          const numberOfExcludedRecords = cachedResponse.tasks.length - filteredTasks.length;

          // console.log('number of removed records: ', numberOfExcludedRecords);

          state.cachedResponses[key].tasks = filteredTasks;
          // console.log('gets here');
          // This could error if this is never set to a number but it should be probably
          // state.cachedResponses[key].total_task_count -= numberOfExcludedRecords;
          // console.log('dies after this somehow????');

          addToUrlCount(groupedKeys, key, numberOfExcludedRecords);
          // console.log('my new tasks should be:', cachedResponse.tasks.filter((task) => !taskIds.includes(task.id)));

          // TODO: Make sure this doesn't screw up the pagination in any way
          // The only true way to make this accurate would be to compare the filter/search text
          // Then collect the removed tasks for each tab + filter + search combination
          // Then remove the total from each one that is from the same "dataset" and remove total from each one.
        }
      });
      const urlsWithRemovedTaskCount = createUrlCountObject(groupedKeys);

      // console.log('my urls with their removed counts: ', urlsWithRemovedTaskCount);

      // TODO: Also need to verify that there isn't an unreachable page anymore.
      // So need to do a calculation based on the total number of tasks to remove the last page.
      // However, this will result in unreachable tasks that are cached which is not great.
      // This could have already happened very infrequently in queue table though if tasks were updated and moved.
      // You just have to hope that the last page wasn't already cached.
      Object.keys(state.cachedResponses).forEach((key) => {
        const cachedResponse = state.cachedResponses[key];
        // const taskCount = cachedResponse.total_task_count;
        const itemsPerPage = cachedResponse.tasks_per_page;
        // total_task_count(pin):42

        // const newPages = calculatePages(itemsPerPage, state.cachedResponses[key].total_task_count);
        // console.log('total task count before action: ', taskCount);

        // calculatePages(state.cachedResponses[])

        if (cachedResponse.tasks && Array.isArray(cachedResponse.tasks)) {
          state.cachedResponses[key].total_task_count -= urlsWithRemovedTaskCount[key];
          state.task_page_count = calculatePages(itemsPerPage, state.cachedResponses[key].total_task_count);
        }

        // TODO: could potentially remove the cachedResponse if it has a page key that is equal to the new page count

      });

    }
  },
});

export const {
  reset,
  updateQueueTableCache,
  removeTaskIdsFromCache
} = queueTableCacheSlice.actions;

export default queueTableCacheSlice.reducer;
