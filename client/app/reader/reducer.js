/* eslint-disable max-lines */
import * as Constants from './constants';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName, update, moveModel } from './utils';
import { searchString, commentContainsWords, categoryContainsWords } from './search';
import { timeFunction } from '../util/PerfDebug';

const updateFilteredDocIds = (nextState) => {
  const { docFilterCriteria } = nextState.ui;
  const activeCategoryFilters = _(docFilterCriteria.category).
        toPairs().
        filter((([key, value]) => value)). // eslint-disable-line no-unused-vars
        map(([key]) => categoryFieldNameOfCategoryName(key)).
        value();

  const activeTagFilters = _(docFilterCriteria.tag).
        toPairs().
        filter((([key, value]) => value)). // eslint-disable-line no-unused-vars
        map(([key]) => key).
        value();

  const updateListComments = (state, id, foundComment) => {
    return update(state, {
      documents: {
        [id]: {
          listComments: {
            $set: foundComment
          }
        }
      }
    });
  };

  const updateSearchCategoryHighlights = (state, docId, categoryMatches) => {
    return update(state, {
      ui: {
        searchCategoryHighlights: {
          $merge: {
            [docId]: {
              ...categoryMatches
            }
          }
        }
      }
    });
  };

  const searchQuery = _.get(docFilterCriteria, 'searchQuery', '').toLowerCase();
  let updatedNextState = nextState;

  const filteredIds = _(nextState.documents).
    filter(
      (doc) => !activeCategoryFilters.length ||
        _.some(activeCategoryFilters, (categoryFieldName) => doc[categoryFieldName])
    ).
    filter(
      (doc) => !activeTagFilters.length ||
        _.some(activeTagFilters, (tagText) => _.find(doc.tags, { text: tagText }))
    ).
    filter(
      searchString(searchQuery, nextState)
    ).
    sortBy(docFilterCriteria.sort.sortBy).
    map('id').
    value();

  // looping through all the documents to update category highlights and expanding comments
  _.forEach(updatedNextState.documents, (doc) => {
    const containsWords = commentContainsWords(searchQuery, updatedNextState, doc);

    // getting all the truthy values from the object
    // {'medical': true, 'procedural': false } turns into {'medical': true}
    const matchesCategories = _.pickBy(categoryContainsWords(searchQuery, doc));

    // update the state for all the search category highlights
    if (matchesCategories !== updatedNextState.ui.searchCategoryHighlights[doc.id]) {
      updatedNextState = updateSearchCategoryHighlights(updatedNextState,
        doc.id, matchesCategories);
    }

    // updating the state of all annotations for expanded comments
    if (containsWords !== doc.listComments) {
      updatedNextState = updateListComments(updatedNextState, doc.id, containsWords);
    }
  });

  if (docFilterCriteria.sort.sortAscending) {
    filteredIds.reverse();
  }

  return update(updatedNextState, {
    ui: {
      filteredDocIds: {
        $set: filteredIds
      }
    }
  });
};

const setErrorMessageState = (state, errorMessageKey, errorMessageVal) =>
  update(
    state,
    { ui: { pdfSidebar: { showErrorMessage: { [errorMessageKey]: { $set: errorMessageVal } } } } },
  );

const hideErrorMessage = (state, errorMessageType) => setErrorMessageState(state, errorMessageType, false);
const showErrorMessage = (state, errorMessageType) => setErrorMessageState(state, errorMessageType, true);

const updateLastReadDoc = (state, docId) =>
  update(
    state,
    {
      ui: {
        pdfList: {
          lastReadDocId: {
            $set: docId
          }
        }
      }
    }
  );

const openAnnotationDeleteModalFor = (state, annotationId) =>
  update(state, {
    ui: {
      deleteAnnotationModalIsOpenFor: {
        $set: annotationId
      }
    }
  });

const initialShowErrorMessageState = {
  tag: false,
  category: false,
  annotation: false
};

export const initialState = {
  assignments: [],
  assignmentsLoaded: false,
  loadedAppealId: null,
  loadedAppeal: {},
  initialDataLoadingFail: false,
  didLoadAppealFail: false,
  initialCaseLoadingFail: false,
  viewingDocumentsOrComments: Constants.DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS,
  pageCoordsBounds: {},
  placingAnnotationIconPageCoords: null,
  openedAccordionSections: [
    'Document information', 'Categories', 'Issue tags', Constants.COMMENT_ACCORDION_KEY
  ],
  ui: {
    searchCategoryHighlights: {},
    pendingAnnotations: {},
    pendingEditingAnnotations: {},
    selectedAnnotationId: null,
    deleteAnnotationModalIsOpenFor: null,
    placedButUnsavedAnnotation: null,
    filteredDocIds: null,
    docFilterCriteria: {
      sort: {
        sortBy: 'receivedAt',
        sortAscending: true
      },
      category: {},
      tag: {},
      searchQuery: ''
    },
    pdf: {
      pdfsReadyToShow: {},
      isPlacingAnnotation: false,
      hidePdfSidebar: false,
      jumpToPageNumber: null
    },
    pdfSidebar: {
      showErrorMessage: initialShowErrorMessageState
    },
    pdfList: {
      scrollTop: null,
      lastReadDocId: null,
      dropdowns: {
        tag: false,
        category: false
      }
    }
  },
  tagOptions: [],

  /**
   * `editingAnnotations` is an object of annotations that are currently being edited.
   * When a user starts editing an annotation, we copy it from `annotations` to `editingAnnotations`.
   * To commit the edits, we copy from `editingAnnotations` back into `annotations`.
   * To discard the edits, we delete from `editingAnnotations`.
   */
  editingAnnotations: {},
  annotations: {},
  documents: {}
};

export const reducer = (state = initialState, action = {}) => {
  let allTags;
  let uniqueTags;
  let modifiedDocuments;

  switch (action.type) {
  case Constants.COLLECT_ALL_TAGS_FOR_OPTIONS:
    allTags = Array.prototype.concat.apply([], _(action.payload).
      map((doc) => {
        return doc.tags ? doc.tags : [];
      }).
      value());
    uniqueTags = _.uniqWith(allTags, _.isEqual);

    return update(
      state,
      {
        tagOptions: {
          $set: uniqueTags
        }
      }
    );
  case Constants.REQUEST_INITIAL_DATA_FAILURE:
    return update(state, {
      initialDataLoadingFail: {
        $set: action.payload.value
      }
    });
  case Constants.REQUEST_INITIAL_CASE_FAILURE:
    return update(state, {
      initialCaseLoadingFail: {
        $set: action.payload.value
      }
    });
  case Constants.RECEIVE_DOCUMENTS:
    return updateFilteredDocIds(update(
      state,
      {
        documents: {
          $set: _(action.payload.documents).
            map((doc) => [
              doc.id, {
                ...doc,
                receivedAt: doc.received_at,
                listComments: false
              }
            ]).
            fromPairs().
            value()
        },
        loadedAppealId: {
          $set: action.payload.vacolsId
        },
        assignments: {
          $apply: (existingAssignments) =>
            existingAssignments.map((assignment) => ({
              ...assignment,
              viewed: assignment.vacols_id === action.payload.vacolsId ? true : assignment.viewed
            }))
        }
      }
    ));
  case Constants.RECEIVE_ANNOTATIONS:
    return updateFilteredDocIds(update(
      state,
      {
        annotations: {
          $set: _(action.payload.annotations).
            map((annotation) => ({
              documentId: annotation.document_id,
              uuid: annotation.id,
              ...annotation
            })).
            keyBy('id').
            value()
        }
      }
    ));
  case Constants.RECEIVE_ASSIGNMENTS:
    return update(state,
      {
        assignments: {
          $set: action.payload.assignments
        },
        assignmentsLoaded: {
          $set: true
        }
      });
  case Constants.RECEIVE_APPEAL_DETAILS:
    return update(state,
      {
        loadedAppeal: {
          $set: action.payload.appeal
        }
      }
    );
  case Constants.RECEIVE_APPEAL_DETAILS_FAILURE:
    return update(state,
      {
        didLoadAppealFail: {
          $set: action.payload.failedToLoad
        }
      }
    );
  case Constants.SET_SEARCH:
    return updateFilteredDocIds(update(state, {
      ui: {
        docFilterCriteria: {
          searchQuery: {
            $set: action.payload.searchQuery
          }
        }
      }
    }));
  case Constants.SET_SORT:
    return updateFilteredDocIds(update(state, {
      ui: {
        docFilterCriteria: {
          sort: {
            sortBy: {
              $set: action.payload.sortBy
            },
            sortAscending: {
              $apply: (prevVal) => !prevVal
            }
          }
        }
      }
    }));
  case Constants.SELECT_CURRENT_VIEWER_PDF:
    return updateLastReadDoc(update(state, {
      ui: {
        pdfSidebar: { showErrorMessage: { $set: initialShowErrorMessageState } }
      },
      documents: {
        [action.payload.docId]: {
          $merge: {
            opened_by_current_user: true
          }
        }
      }
    }), action.payload.docId);
  case Constants.SET_PDF_READY_TO_SHOW:
    return update(state, {
      ui: {
        pdf: {
          pdfsReadyToShow: {
            $set: {
              [action.payload.docId]: true
            }
          }
        }
      }
    });
  case Constants.TOGGLE_DOCUMENT_CATEGORY:
    return update(
      hideErrorMessage(state, 'category'),
      {
        documents: {
          [action.payload.docId]: {
            [action.payload.categoryKey]: {
              $set: action.payload.toggleState
            }
          }
        }
      }
    );
  case Constants.TOGGLE_DOCUMENT_CATEGORY_FAIL:
    return update(
      showErrorMessage(state, 'category'),
      {
        documents: {
          [action.payload.docId]: {
            [action.payload.categoryKey]: {
              $set: action.payload.categoryValueToRevertTo
            }
          }
        }
      }
    );
  case Constants.TOGGLE_FILTER_DROPDOWN:
    return (() => {
      const originalValue = _.get(
        state,
        ['ui', 'pdfList', 'dropdowns', action.payload.filterName],
        false
      );

      return update(state,
        {
          ui: {
            pdfList: {
              dropdowns: {
                [action.payload.filterName]: {
                  $set: !originalValue
                }
              }
            }
          }
        }
      );
    })();
  case Constants.REQUEST_NEW_TAG_CREATION:
    return update(hideErrorMessage(state, 'tag'), {
      documents: {
        [action.payload.docId]: {
          tags: {
            $push: action.payload.newTags
          }
        }
      }
    });
  case Constants.REQUEST_NEW_TAG_CREATION_FAILURE:
    return update(showErrorMessage(state, 'tag'), {
      documents: {
        [action.payload.docId]: {
          tags: {
            $apply: (tags) =>
              _.differenceBy(
                tags,
                action.payload.tagsThatWereAttemptedToBeCreated,
                'text'
              )
          }
        }
      }
    });
  case Constants.REQUEST_NEW_TAG_CREATION_SUCCESS:
    return update(
      state,
      {
        documents: {
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
        }
      }
    );
  case Constants.SET_CATEGORY_FILTER:
    return updateFilteredDocIds(update(
      state,
      {
        ui: {
          docFilterCriteria: {
            category: {
              [action.payload.categoryName]: {
                $set: action.payload.checked
              }
            }
          }
        }
      }));
  case Constants.JUMP_TO_PAGE:
    return update(
      state,
      {
        ui: {
          pdf: {
            $merge: {
              jumpToPageNumber: action.payload.pageNumber
            }
          }
        }
      }
    );
  case Constants.RESET_JUMP_TO_PAGE:
    return update(
      state,
      {
        ui: {
          pdf: {
            $merge: {
              jumpToPageNumber: null
            }
          }
        }
      }
    );
  case Constants.SET_TAG_FILTER:
    return updateFilteredDocIds(update(
      state,
      {
        ui: {
          docFilterCriteria: {
            tag: {
              [action.payload.text]: {
                $set: action.payload.checked
              }
            }
          }
        }
      }));
  case Constants.CLEAR_TAG_FILTER:
    return updateFilteredDocIds(update(
      state,
      {
        ui: {
          docFilterCriteria: {
            tag: {
              $set: {}
            }
          }
        }
      }
    ));
  case Constants.CLEAR_CATEGORY_FILTER:
    return updateFilteredDocIds(update(
      state,
      {
        ui: {
          docFilterCriteria: {
            category: {
              $set: {}
            }
          }
        }
      }
    ));
  case Constants.CLEAR_ALL_FILTERS:
    return updateFilteredDocIds(update(
      state,
      {
        ui: {
          docFilterCriteria: {
            category: {
              $set: {}
            },
            tag: {
              $set: {}
            }
          }
        },
        viewingDocumentsOrComments: {
          $set: Constants.DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS
        }
      }));
  case Constants.REQUEST_REMOVE_TAG:
    return update(state, {
      documents: {
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
      }
    });
  case Constants.REQUEST_REMOVE_TAG_SUCCESS:
    return update(hideErrorMessage(state, 'tag'), {
      documents: {
        [action.payload.docId]: {
          tags: {
            $apply: (tags) => _.reject(tags, { id: action.payload.tagId })
          }
        }
      }
    });
  case Constants.OPEN_ANNOTATION_DELETE_MODAL:
    return openAnnotationDeleteModalFor(state, action.payload.annotationId);
  case Constants.CLOSE_ANNOTATION_DELETE_MODAL:
    return openAnnotationDeleteModalFor(state, null);
  case Constants.REQUEST_DELETE_ANNOTATION:
    return update(
      hideErrorMessage(openAnnotationDeleteModalFor(state, null), 'annotation'),
      {
        editingAnnotations: {
          [action.payload.annotationId]: {
            $apply: (annotation) => annotation && {
              ...annotation,
              pendingDeletion: true
            }
          }
        },
        annotations: {
          [action.payload.annotationId]: {
            $merge: {
              pendingDeletion: true
            }
          }
        }
      }
    );
  case Constants.REQUEST_DELETE_ANNOTATION_FAILURE:
    return update(showErrorMessage(state, 'annotation'), {
      editingAnnotations: {
        [action.payload.annotationId]: {
          $unset: 'pendingDeletion'
        }
      },
      annotations: {
        [action.payload.annotationId]: {
          $unset: 'pendingDeletion'
        }
      }
    });
  case Constants.REQUEST_DELETE_ANNOTATION_SUCCESS:
    return update(
      state,
      {
        editingAnnotations: {
          $unset: action.payload.annotationId
        },
        annotations: {
          $unset: action.payload.annotationId
        }
      }
    );
  case Constants.REQUEST_MOVE_ANNOTATION:
    return update(hideErrorMessage(state, 'annotation'), {
      ui: {
        pendingEditingAnnotations: {
          [action.payload.annotation.id]: {
            $set: action.payload.annotation
          }
        }
      }
    });
  case Constants.REQUEST_MOVE_ANNOTATION_SUCCESS:
    return moveModel(
      state,
      ['ui', 'pendingEditingAnnotations'],
      ['annotations'],
      action.payload.annotationId
    );
  case Constants.REQUEST_MOVE_ANNOTATION_FAILURE:
    return update(showErrorMessage(state, 'annotation'), {
      ui: {
        pendingEditingAnnotations: {
          $unset: action.payload.annotationId
        }
      }
    });
  case Constants.SET_PAGE_COORD_BOUNDS:
    return update(state, {
      pageCoordsBounds: {
        $set: action.payload.coordBounds
      }
    });
  case Constants.PLACE_ANNOTATION:
    return update(state, {
      ui: {
        placedButUnsavedAnnotation: {
          $set: {
            ...action.payload,
            class: 'Annotation',
            type: 'point'
          }
        },
        pdf: {
          isPlacingAnnotation: { $set: false }
        }
      }
    });
  case Constants.START_PLACING_ANNOTATION:
    return update(state, {
      ui: {
        pdf: {
          isPlacingAnnotation: { $set: true }
        }
      },
      openedAccordionSections: {
        $apply: (sectionKeys) => _.union(sectionKeys, [Constants.COMMENT_ACCORDION_KEY])
      }
    });
  case Constants.SHOW_PLACE_ANNOTATION_ICON:
    return update(state, {
      placingAnnotationIconPageCoords: {
        $set: {
          pageIndex: action.payload.pageIndex,
          ...action.payload.pageCoords
        }
      }
    });
  case Constants.STOP_PLACING_ANNOTATION:
    return update(state, {
      placingAnnotationIconPageCoords: {
        $set: null
      },
      ui: {
        placedButUnsavedAnnotation: { $set: null },
        pdf: {
          isPlacingAnnotation: { $set: false }
        }
      }
    });
  case Constants.REQUEST_CREATE_ANNOTATION:
    return update(hideErrorMessage(state, 'annotation'), {
      ui: {
        placedButUnsavedAnnotation: { $set: null },
        pendingAnnotations: {
          [action.payload.annotation.id]: {
            $set: action.payload.annotation
          }
        }
      }
    });
  case Constants.REQUEST_CREATE_ANNOTATION_SUCCESS:
    return update(state, {
      ui: {
        pendingAnnotations: {
          $unset: action.payload.annotationTemporaryId
        }
      },
      annotations: {
        [action.payload.annotation.id]: {
          $set: {
            // These two duplicate fields exist on annotations throughout the app.
            // I am not sure why this is, but we'll patch it here to make everything work.
            document_id: action.payload.annotation.documentId,
            uuid: action.payload.annotation.id,

            ...action.payload.annotation
          }
        }
      }
    });
  case Constants.REQUEST_CREATE_ANNOTATION_FAILURE:
    return update(showErrorMessage(state, 'annotation'), {
      ui: {
        // This will cause a race condition if the user has created multiple annotations.
        // Whichever annotation failed most recently is the one that'll be in the
        // "new annotation" text box. For now, I think that's ok.
        placedButUnsavedAnnotation: {
          $set: state.ui.pendingAnnotations[action.payload.annotationTemporaryId]
        },
        pendingAnnotations: {
          $unset: action.payload.annotationTemporaryId
        }
      }
    });
  case Constants.START_EDIT_ANNOTATION:
    return update(state, {
      editingAnnotations: {
        [action.payload.annotationId]: {
          $set: state.annotations[action.payload.annotationId]
        }
      }
    });
  case Constants.CANCEL_EDIT_ANNOTATION:
    return update(state, {
      editingAnnotations: {
        $unset: action.payload.annotationId
      }
    });
  case Constants.UPDATE_ANNOTATION_CONTENT:
    return update(state, {
      editingAnnotations: {
        [action.payload.annotationId]: {
          comment: {
            $set: action.payload.content
          }
        }
      }
    });
  case Constants.UPDATE_NEW_ANNOTATION_CONTENT:
    return update(state, {
      ui: {
        placedButUnsavedAnnotation: {
          comment: {
            $set: action.payload.content
          }
        }
      }
    });
  case Constants.REQUEST_EDIT_ANNOTATION:
    return moveModel(
      hideErrorMessage(state, 'annotation'),
      ['editingAnnotations'],
      ['ui', 'pendingEditingAnnotations'],
      action.payload.annotationId
    );
  case Constants.REQUEST_EDIT_ANNOTATION_SUCCESS:
    return moveModel(
      hideErrorMessage(state, 'annotation'),
      ['ui', 'pendingEditingAnnotations'],
      ['annotations'],
      action.payload.annotationId
    );
  case Constants.REQUEST_EDIT_ANNOTATION_FAILURE:
    return moveModel(
      showErrorMessage(state, 'annotation'),
      ['ui', 'pendingEditingAnnotations'],
      ['editingAnnotations'],
      action.payload.annotationId
    );
  case Constants.SELECT_ANNOTATION:
    return update(state, {
      ui: {
        selectedAnnotationId: {
          $set: action.payload.annotationId
        }
      }
    });
  case Constants.SCROLL_TO_SIDEBAR_COMMENT:
    return update(state, {
      ui: {
        pdf: {
          scrollToSidebarComment: { $set: action.payload.scrollToSidebarComment }
        }
      }
    });
  case Constants.SET_DOC_LIST_SCROLL_POSITION:
    return update(state, {
      ui: {
        pdfList: {
          scrollTop: { $set: action.payload.scrollTop }
        }
      }
    });
  case Constants.REQUEST_REMOVE_TAG_FAILURE:
    return update(showErrorMessage(state, 'tag'), {
      documents: {
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
      }
    });
  case Constants.SCROLL_TO_COMMENT:
    return update(state, {
      ui: { pdf: { scrollToComment: { $set: action.payload.scrollToComment } } }
    });
  case Constants.TOGGLE_COMMENT_LIST:
    modifiedDocuments = update(state.documents,
      {
        [action.payload.docId]: {
          $merge: {
            listComments: !state.documents[action.payload.docId].listComments
          }
        }
      });

    return update(
      state,
      {
        documents: { $set: modifiedDocuments }
      });
  case Constants.TOGGLE_PDF_SIDEBAR:
    return _.merge(
      {},
      state,
      {
        ui: {
          pdf: {
            hidePdfSidebar: !state.ui.pdf.hidePdfSidebar
          }
        }
      }
    );
  case Constants.LAST_READ_DOCUMENT:
    return updateLastReadDoc(state, action.payload.docId);
  case Constants.CLEAR_ALL_SEARCH:
    return updateFilteredDocIds(update(
      state,
      {
        ui: {
          docFilterCriteria: {
            searchQuery: {
              $set: ''
            }
          }
        }
      }
    ));
  case Constants.SET_OPENED_ACCORDION_SECTIONS:
    return update(
      state,
      {
        openedAccordionSections: {
          $set: action.payload.openedAccordionSections
        }
      }
    );
  case Constants.SET_VIEWING_DOCUMENTS_OR_COMMENTS:
    return update(
      state,
      {
        viewingDocumentsOrComments: {
          $set: action.payload.documentsOrComments
        },
        documents: {
          $apply: (docs) =>
            _.mapValues(docs, (doc) => ({
              ...doc,
              listComments: action.payload.documentsOrComments === Constants.DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS
            }))
        }
      }
    );
  default:
    return state;
  }
};

export default timeFunction(
  reducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
