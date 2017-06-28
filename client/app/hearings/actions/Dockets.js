import * as Constants from '../constants/constants';

export const docketsAreLoaded = () => ({
  type: Constants.DOCKETS_LOADED
});

export const populateDockets = (dockets) => ({
  type: Constants.POPULATE_DOCKETS,
  payload: {
    dockets
  }
});
