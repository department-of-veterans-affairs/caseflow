import { storeMetrics } from '../../util/Metrics';
// Function to calculate download progress as the document loads
const calculateProgress = ({ loaded, fileSize }) => {
  let percentage = 0;

  if (fileSize > 0) {
    percentage = ((loaded / fileSize) * 100).toFixed(0);
  }

  return Number(percentage);
};

// Function to check if the progress bar should be shown
// Returns a boolean based on params passed in and the 2 variables passed in as progressBarOptions
const shouldShowProgressBar = ({ elapsedTime, downloadSpeed, percentage, loaded, fileSize, readerPreferences }) => {

  const delayBeforeProgressBar = readerPreferences.delayBeforeProgressBar;
  const showProgressBarThreshold = readerPreferences.showProgressBarThreshold;

  if (!delayBeforeProgressBar || !showProgressBarThreshold) {
    return false;
  }
  if (percentage < 100 && elapsedTime > delayBeforeProgressBar) {
    const projectedEndTime = (fileSize - loaded) / downloadSpeed;

    if (projectedEndTime > showProgressBarThreshold) {
      return true;
    }
  }

  return false;
};

const logCancelRequest = ({ progressData, documentId, userId, getStartTime }) => {
  const { progressPercentage, loadedBytes, totalBytes } = progressData;

  const elapsedTime = new Date().getTime() - (getStartTime || 0);
  const downloadSpeed = Number((loadedBytes / (elapsedTime) * 0.01).toFixed(1));

  storeMetrics(
    documentId,
    {
      user_id: userId,
      download_percent: progressPercentage,
      document_size_bytes: totalBytes,
      elapsed_time_ms: elapsedTime,
      download_speed_mbits_sec: downloadSpeed,
    },
    {
      message: 'Reader Progress Bar User Cancelled Request',
      type: 'performance',
      product: 'reader prototype',
      start: null,
      end: null,
      duration: null,
    },
    null
  );
};

const ProgressBarUtil = {
  calculateProgress,
  shouldShowProgressBar,
  logCancelRequest,
};

export default ProgressBarUtil;
