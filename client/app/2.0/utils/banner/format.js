export const listWithOxfordComma = (list) => {
  return new Intl.ListFormat('en', { style: 'long' }).format(list);

};
