import { createStore } from 'redux';

import reducer from 'app/hearings/reducers';

export const detailsStore = createStore(
  reducer,
  {
    components: {
      dropdowns: {
        hearingCoordinators: {
          isFetching: false,
          options: []
        }
      }
    }
  }
);
