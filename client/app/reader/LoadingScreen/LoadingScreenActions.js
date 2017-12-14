import * as Constants from '../constants';

export const setLoadedVacolsId = (vacolsId) => ({
  type: Constants.SET_LOADED_APPEAL_ID,
  payload: {
    vacolsId
  }
});

export const onReceiveManifests = (manifestVbmsFetchedAt, manifestVvaFetchedAt) => ({
  type: Constants.RECEIVE_MANIFESTS,
  payload: { manifestVbmsFetchedAt,
    manifestVvaFetchedAt }
});

