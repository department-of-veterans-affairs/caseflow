import * as Constants from './constants';

export const collectAllTags = (documents) => ({
  type: Constants.COLLECT_ALL_TAGS_FOR_OPTIONS,
  payload: documents
});

