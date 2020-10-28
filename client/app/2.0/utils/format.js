import moment from 'moment';

export const CACHE_TIMEOUT_HOURS = 3;

/**
 * Helper Method to format the times for the Last Retrieval Alert
 * @param {string} manifestVbmsFetchedAt -- The last time the VBMS Manifest was fetched
 * @param {string} manifestVvaFetchedAt -- The last time the VVA Manifest was fetched
 */
export const formatAlertTime = (manifestVbmsFetchedAt, manifestVvaFetchedAt) => {
  // Create the formatted times
  const formattedTimes = {
    staleCacheTime: moment().subtract(CACHE_TIMEOUT_HOURS, 'h'),
    vbmsTimestamp: moment(manifestVbmsFetchedAt, 'MM/DD/YY HH:mma Z'),
    vvaTimestamp: moment(manifestVvaFetchedAt, 'MM/DD/YY HH:mma Z'),
  };

  // Calculate whether the cache is stale
  const stale = formattedTimes.vbmsTimestamp.isBefore(formattedTimes.staleCacheTime) ||
    formattedTimes.vvaTimestamp.isBefore(formattedTimes.staleCacheTime);

  // Check that document manifests have been received from VVA and VBMS
  if (stale) {
    // Calculate the time
    formattedTimes.now = moment();
    formattedTimes.vbmsDiff = formattedTimes.diff(formattedTimes.vbmsTimestamp, 'hours');
    formattedTimes.vvaDiff = formattedTimes.diff(formattedTimes.vvaTimestamp, 'hours');
  }

  // Return all of the Formatted Times
  return formattedTimes;
};
