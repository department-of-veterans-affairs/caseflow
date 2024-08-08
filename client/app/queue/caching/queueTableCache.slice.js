import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  cachedResponses: {},
};

// Helper functions for removing tasks from the cachedResponses.
const generateKeyFromUrl = (urlString) => {
  // Split the url to only have get params from the cached url key
  const params = new URLSearchParams(urlString.split('?')[1]);
  const filter = params.get('filter');
  const tab = params.get('tab');

  // Create a group key based on filter and tab values
  const groupKey = `filter=${filter}&tab=${tab}`;

  return groupKey;
};

const groupUrlKeysByParams = (urlKeys) => {
  const groups = {};

  Object.keys(urlKeys).forEach((urlString) => {
    const groupKey = generateKeyFromUrl(urlString);

    // Initialize the group if it doesn't exist
    if (!groups[groupKey]) {
      groups[groupKey] = {
        urls: [],
        count: 0
      };
    }

    // Add the URL key to the corresponding group
    groups[groupKey].urls.push(urlString);
  });

  return groups;
};

const addToUrlCount = (groupedUrls, urlString, number) => {
  const groupKey = generateKeyFromUrl(urlString);

  // Keep a grouped count of shared tasks between similar cached task pages
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
// End of helper functions

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

      const groupedKeys = groupUrlKeysByParams(state.cachedResponses);

      Object.keys(state.cachedResponses).forEach((key) => {
        const cachedResponse = state.cachedResponses[key];

        if (cachedResponse.tasks && Array.isArray(cachedResponse.tasks)) {
          const filteredTasks = cachedResponse.tasks.filter((task) => !taskIds.includes(task.id));
          const numberOfExcludedRecords = cachedResponse.tasks.length - filteredTasks.length;

          state.cachedResponses[key].tasks = filteredTasks;

          addToUrlCount(groupedKeys, key, numberOfExcludedRecords);
        }
      });

      const urlsWithRemovedTaskCount = createUrlCountObject(groupedKeys);

      Object.keys(state.cachedResponses).forEach((key) => {
        const cachedResponse = state.cachedResponses[key];
        const itemsPerPage = cachedResponse.tasks_per_page;

        if (cachedResponse.tasks && Array.isArray(cachedResponse.tasks)) {
          state.cachedResponses[key].total_task_count -= urlsWithRemovedTaskCount[key];
          state.task_page_count = calculatePages(itemsPerPage, state.cachedResponses[key].total_task_count);
        }
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
