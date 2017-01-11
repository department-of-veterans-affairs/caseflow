export const leftPad = function (string, width, padding = '0') {
  let padded = '';

  for (let i = 0; i < width; i++) {
    padded += padding;
  }

  return (padded + string).slice(-width);
};
