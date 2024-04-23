import { find, pick, findIndex, differenceBy, fromPairs, get, isNil, map, reject } from 'lodash';

import * as Constants from '../Documents/actionTypes';
import { update } from '../../util/ReducerUtil';

export const initialState = {};

const documentsReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.ASSIGN_DOCUMENTS:
    return Object.assign({}, action.payload.documents);
  case Constants.RECEIVE_DOCUMENTS:
    return fromPairs(map(action.payload.documents, (doc) => [
      doc.id,
      {
        ...doc,
        receivedAt: doc.received_at,
        listComments: false,
        wasUpdated: !isNil(doc.previous_document_version_id) && !doc.opened_by_current_user
      }
    ])
    );
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
  case Constants.TOGGLE_COMMENT_LIST:
    return update(state, {
      [action.payload.docId]: {
        $merge: {
          listComments: !state[action.payload.docId].listComments
        }
      }
    });
  case Constants.ROTATE_PDF_DOCUMENT: {
    const rotation =
        (get(state, [action.payload.docId, 'rotation'], 0) + Constants.ROTATION_INCREMENTS) %
        Constants.COMPLETE_ROTATION;

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
          $apply: (tags) => differenceBy(tags, action.payload.tagsThatWereAttemptedToBeCreated, 'text')
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
          $apply: (docTags) => map(docTags, (docTag) => {
            if (!docTag.temporaryId) {
              return docTag;
            }

            const createdTag = find(action.payload.createdTags, pick(docTag, 'text'));

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
            const removedTagIndex = findIndex(tags, { id: action.payload.tagId });

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
          $apply: (tags) => reject(tags, { id: action.payload.tagId })
        }
      }
    });
  case Constants.REQUEST_REMOVE_TAG_FAILURE:
    return update(state, {
      [action.payload.docId]: {
        tags: {
          $apply: (tags) => {
            const removedTagIndex = findIndex(tags, { id: action.payload.tagId });

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
  case Constants.CHANGE_PENDING_DOCUMENT_DESCRIPTION:
    return update(state, {
      [action.payload.docId]: {
        pendingDescription: {
          $set: action.payload.description
        }
      }
    });
  case Constants.RESET_PENDING_DOCUMENT_DESCRIPTION:
    return update(state, {
      [action.payload.docId]: {
        $unset: 'pendingDescription'
      }
    });
  case Constants.SAVE_DOCUMENT_DESCRIPTION_SUCCESS:
    return update(state, {
      [action.payload.docId]: {
        description: {
          $set: action.payload.description
        }
      }
    });
  case Constants.CLOSE_DOCUMENT_UPDATED_MODAL:
    return update(state, {
      [action.payload.docId]: {
        wasUpdated: {
          $set: false
        }
      }
    });
  default:
    return state;
  }
};

export default documentsReducer;
