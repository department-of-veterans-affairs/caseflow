const ZERO_INDEX_MONTH_OFFSET = 1;

function pad(string, width, padding) {
  padding = padding || '0';
  let padded = '';
  for (let i = 0; i < width; i++)
  {
    padded = padded + padding;
  }
  return (padded + string).slice(-width);
}

export const formatDate = function(dateString) {
  let date = new Date(dateString);

  let value = `${pad(date.getMonth() + ZERO_INDEX_MONTH_OFFSET, 2, '0')}` +
    `/${pad(date.getDate(), 2, '0')}/${date.getFullYear()}`;

  return value;
};
