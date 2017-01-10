const ZERO_INDEX_MONTH_OFFSET = 1;

export const pad = function (string, width, padding = '0') {
  let padded = '';

  for (let i = 0; i < width; i++) {
    padded += padding;
  }

  return (padded + string).slice(-width);
};

export const formatDate = function(dateString) {
  let date = new Date(dateString);
  let month = pad(date.getMonth() + ZERO_INDEX_MONTH_OFFSET, 2, '0');
  let day = pad(date.getDate(), 2, '0');
  let year = date.getFullYear();

  return `${month}/${day}/${year}`;
};
