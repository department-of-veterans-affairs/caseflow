const ZERO_INDEX_MONTH_OFFSET = 1;

const pad = function (string, width, padding = '0') {
  let padded = '';

  for (let i = 0; i < width; i++) {
    padded += padding;
  }

  return (padded + string).slice(-width);
};

export const formatDate = function(dateString) {
  let date = new Date(dateString);

  let value = `${pad(date.getMonth() + ZERO_INDEX_MONTH_OFFSET, 2, '0')}` +
    `/${pad(date.getDate(), 2, '0')}/${date.getFullYear()}`;

  return value;
};
