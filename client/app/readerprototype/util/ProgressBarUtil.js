// Below are customizable values that determine wait times for document loading
// and are then used to decide whether or not we show the progress bar

const minimumInitialWait = 1000; // Inital wait time in milliseconds
const significantAdditionalWait = 3; // time in seconds

// Function to calculate download progress as the document loads
const calculateProgress = ({ loaded, file_size }) => {
  let percentage = 0;
  if (file_size > 0) {
    percentage = ((loaded / file_size) * 100).toFixed(0);
  }
  return percentage;
};

// Function to check if the progress bar should be shown
// Returns a boolean based on params passed in and the 2 variables we set at the
// top of this util file (minimumInitialWait, significantAdditionalWait)
const shouldShowProgressBar = (enlapsedTime, downloadSpeed, percentage, loaded, file_size) => {
  if (percentage < 100 && enlapsedTime > minimumInitialWait) {
    const projectedEndTime = (file_size - loaded) / downloadSpeed;
    if (projectedEndTime > significantAdditionalWait) {
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
