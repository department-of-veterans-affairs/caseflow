
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
const shouldShowProgressBar = ({ enlapsedTime, downloadSpeed, percentage, loaded, fileSize, readerPreferences }) => {

  const delayBeforeProgressBar = readerPreferences.delayBeforeProgressBar;
  const showProgressBarThreshold = readerPreferences.showProgressBarThreshold;

  if (!delayBeforeProgressBar || !showProgressBarThreshold) {
    return false;
  }
  if (percentage < 100 && enlapsedTime > delayBeforeProgressBar) {
    const projectedEndTime = (fileSize - loaded) / downloadSpeed;

    if (projectedEndTime > showProgressBarThreshold) {
      return true;
    }
  }

  return false;
};

const ProgressBarUtil = {
  calculateProgress,
  shouldShowProgressBar,
};

export default ProgressBarUtil;
