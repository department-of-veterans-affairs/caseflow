import _ from 'lodash';

import * as Constants from '../Documents/actionTypes';
import { update } from '../../util/ReducerUtil';
import { SET_VIEWING_DOCUMENTS_OR_COMMENTS, DOCUMENTS_OR_COMMENTS_ENUM } from '../DocumentList/actionTypes';

export const initialState = {};

const documentsReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.ASSIGN_DOCUMENTS:
    return Object.assign({}, action.payload.documents);
  case Constants.RECEIVE_DOCUMENTS:
    return _(action.payload.documents).map((doc) => [
      doc.id, {
        ...doc,
        receivedAt: doc.received_at,
        listComments: false
      }
    ]).
      fromPairs().
      value();
  case Constants.TOGGLE_DOCUMENT_CATEGORY_FAIL:
    return update(state, {
      [action.payload.docId]: {
        [action.payload.categoryKey]: {
          $set: action.payload.categoryValueToRevertTo
        }
      }
    });
  case Constants.TOGGLE_DOCUMENT_CATEGORY:
    return update(state, {
      [action.payload.docId]: {
        [action.payload.categoryKey]: {
          $set: action.payload.toggleState
        }
      }
    });
  case SET_VIEWING_DOCUMENTS_OR_COMMENTS:
    return _.mapValues(state, (doc) => ({
      ...doc,
      listComments: action.payload.documentsOrComments === DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS
    }));
  case Constants.TOGGLE_COMMENT_LIST:
    return update(state, {
      [action.payload.docId]: {
        $merge: {
          listComments: !state[action.payload.docId].listComments
        }
      }
    });
  case Constants.ROTATE_PDF_DOCUMENT:
  {
    const rotation = (_.get(state, [
      action.payload.docId, 'rotation'
    ], 0) + Constants.ROTATION_INCREMENTS) % Constants.COMPLETE_ROTATION;

    return update(state, {
      [action.payload.docId]: {
        rotation: {
          $set: rotation
        }
      }
    });
  }
  case Constants.SELECT_CURRENT_VIEWER_PDF:
    return update(state, {
      [action.payload.docId]: {
        $merge: {
          opened_by_current_user: true
        }
      }
    });
  case Constants.REQUEST_NEW_TAG_CREATION:
    return update(state, {
      [action.payload.docId]: {
        tags: {
          $push: action.payload.newTags
        }
      }
    });
  case Constants.REQUEST_NEW_TAG_CREATION_FAILURE:
    return update(state, {
      [action.payload.docId]: {
        tags: {
          $apply: (tags) => _.differenceBy(tags, action.payload.tagsThatWereAttemptedToBeCreated, 'text')
        }
      }
    });
  case Constants.REQUEST_NEW_TAG_CREATION_SUCCESS:
    return update(state, {
      [action.payload.docId]: {
        tags: {

          /**
           * We can't just `$set: action.payload.createdTags` here, because that may wipe out additional tags
           * that have been created on the client since this new tag was created. Consider the following sequence
           * of events:
           *
           *  1) REQUEST_NEW_TAG_CREATION (newTag = 'first')
           *  2) REQUEST_NEW_TAG_CREATION (newTag = 'second')
           *  3) REQUEST_NEW_TAG_CREATION_SUCCESS (newTag = 'first')
           *
           * At this point, the doc tags are [{text: 'first'}, {text: 'second'}].
           * Action (3) gives us [{text: 'first}]. If we just do a `$set`, we'll end up with:
           *
           *  [{text: 'first'}]
           *
           * and we've erroneously erased {text: 'second'}. To fix this, we'll do a merge instead. If we have tags
           * that have not yet been saved on the server, but we see those tags in action.payload.createdTags, we'll
           * merge it in. If the pending tag does not have a corresponding saved tag in action.payload.createdTags,
           * we'll leave it be.
           */
          $apply: (docTags) => _.map(docTags, (docTag) => {
            if (docTag.id) {
              return docTag;
            }

            const createdTag = _.find(action.payload.createdTags, _.pick(docTag, 'text'));

            if (createdTag) {
              return createdTag;
            }

            return docTag;
          })
        }
      }
    });
  case Constants.REQUEST_REMOVE_TAG:
    return update(state, {
      [action.payload.docId]: {
        tags: {
          $apply: (tags) => {
            const removedTagIndex = _.findIndex(tags, { id: action.payload.tagId });

            return update(tags, {
              [removedTagIndex]: {
                $merge: {
                  pendingRemoval: true
                }
              }
            });
          }
        }
      }
    });
  case Constants.REQUEST_REMOVE_TAG_SUCCESS:
    return update(state, {
      [action.payload.docId]: {
        tags: {
          $apply: (tags) => _.reject(tags, { id: action.payload.tagId })
        }
      }
    });
  case Constants.REQUEST_REMOVE_TAG_FAILURE:
    return update(state, {
      [action.payload.docId]: {
        tags: {
          $apply: (tags) => {
            const removedTagIndex = _.findIndex(tags, { id: action.payload.tagId });

            return update(tags, {
              [removedTagIndex]: {
                $merge: {
                  pendingRemoval: false
                }
              }
            });
          }
        }
      }
    });
  default:
    return state;
  }
};

export default documentsReducer;
