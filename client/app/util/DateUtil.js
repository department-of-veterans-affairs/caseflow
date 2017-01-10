const ZERO_INDEX_MONTH_OFFSET = 1;

// This will leftpad a day or month so 1/3 becomes 01/03
export const leftPadDate = (value) => {
  return ("00" + value).slice(-2)
}

export const formatDate = function(dateString) {
  let date = new Date(dateString);

  let month = leftPadDate(date.getMonth() + ZERO_INDEX_MONTH_OFFSET);
  let day = leftPadDate(date.getDate());
  let year = date.getFullYear();

  return `${month}/${day}/${year}`;
};
