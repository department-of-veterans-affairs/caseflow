// Below are customizable values that determine wait times for document loading
// and are then used to decide whether or not we show the progress bar

// times are in milliseconds
const delayBeforeProgressBarDefaultValue = 1000;
const showProgressBarThresholdDefaultValue = 3000;

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
// top of this util file has default values for if not present (delayBeforeProgressBar, showProgressBarThreshold)
const shouldShowProgressBar = ({ enlapsedTime, downloadSpeed, percentage, loaded, fileSize, progressBarOptions }) => {

  const delayBeforeProgressBar = progressBarOptions.delayBeforeProgressBar || delayBeforeProgressBarDefaultValue;
  const showProgressBarThreshold = progressBarOptions.showProgressBarThreshold || showProgressBarThresholdDefaultValue;

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
