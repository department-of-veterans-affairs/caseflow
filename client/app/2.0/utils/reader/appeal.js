// Locate the appeal in the assignments list
export const loadAppeal = (assignments, vacolsId, loadedAppeal) =>
  vacolsId ? find(assignments, { vacols_id: vacolsId }) : loadedAppeal;
