export const connection = () => {
  const speed = (navigator.connection || navigator.mozConnection || navigator.webkitConnection);

  return speed ? speed : null;
};
export const documentDownloadTime = (documentSize, browserSpeedInBytes) => {
  return documentSize / browserSpeedInBytes;
};
export const BYTES_IN_MEGABIT = 125000;
export const megaBitsToBytes = (mbps) => {
  return mbps * BYTES_IN_MEGABIT;
};
