// External Dependencies
import { isEmpty } from 'lodash';

// Locate the appeal in the assignments list
export const loadAppeal = (assignments, vacolsId, loadedAppeal) =>
  vacolsId && !isEmpty(assignments) ? find(assignments, { vacols_id: vacolsId }) : loadedAppeal;
