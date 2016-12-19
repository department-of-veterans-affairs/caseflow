const ZERO_INDEX_MONTH_OFFSET = 1;

export const formatDate = function(dateString) {
  let date = new Date(dateString);

  let value = `${date.getMonth() + ZERO_INDEX_MONTH_OFFSET}` +
    `/${date.getDate()}/${date.getFullYear()}`;

  return value;
};