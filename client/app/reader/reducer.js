/* eslint-disable max-lines */
import * as Constants from './constants';

import _ from 'lodash';

import { update } from '../util/ReducerUtil';
import { categoryFieldNameOfCategoryName, moveModel } from './utils';
import { searchString, commentContainsWords, categoryContainsWords } from './search';
import { timeFunction } from '../util/PerfDebug';
import documentsReducer from './DocumentList/DocumentsReducer';

const updateFilteredDocIds = (nextState) => {
  const { docFilterCriteria } = nextState.ui;
  const activeCategoryFilters = _(docFilterCriteria.category).
    toPairs().
    filter(([key, value]) => value). // eslint-disable-line no-unused-vars
    map(([key]) => categoryFieldNameOfCategoryName(key)).
    value();

  const activeTagFilters = _(docFilterCriteria.tag).
    toPairs().
    filter(([key, value]) => value). // eslint-disable-line no-unused-vars
    map(([key]) => key).
    value();

  const searchQuery = _.get(docFilterCriteria, 'searchQuery', '').toLowerCase();

  // ensure we have a deep clone so we are not mutating the original state
  let updatedNextState = update(nextState, {});

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
      updatedNextState.ui.searchCategoryHighlights[doc.id] = matchesCategories;
    }

    // updating the state of all annotations for expanded comments
    if (containsWords !== doc.listComments) {
      updatedNextState.documents[doc.id].listComments = containsWords;
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

const setErrorMessageState = (state, errorType, isVisible, errorMsg = null) =>
  update(
    state,
    {
      ui: {
        pdfSidebar: {
          error: {
            [errorType]: {
              visible: { $set: isVisible },
              message: { $set: isVisible ? errorMsg : null }
            }
          }
        }
      }
    },
  );

const hideErrorMessage = (state, errorType, errorMsg = null) => setErrorMessageState(state, errorType, false, errorMsg);
const showErrorMessage = (state, errorType, errorMsg = null) => setErrorMessageState(state, errorType, true, errorMsg);

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

const initialPdfSidebarErrorState = {
  tag: { visible: false,
    message: null },
  category: { visible: false,
    message: null },
  annotation: { visible: false,
    message: null }
};

export const initialState = {
  loadedAppealId: null,
  loadedAppeal: {},
  didLoadAppealFail: false,
  viewingDocumentsOrComments: Constants.DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS,
  placingAnnotationIconPageCoords: null,
  openedAccordionSections: [
    'Categories', 'Issue tags', Constants.COMMENT_ACCORDION_KEY
  ],
  ui: {
    tagOptions: [],
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
      jumpToPageNumber: null,
      scrollTop: 0,
      hideSearchBar: true
    },
    pdfSidebar: {
      error: initialPdfSidebarErrorState
    },
    pdfList: {
      scrollTop: null,
      lastReadDocId: null,
      dropdowns: {
        tag: false,
        category: false
      }
    },
    manifestVbmsFetchedAt: null,
    manifestVvaFetchedAt: null
  },

  /**
   * `editingAnnotations` is an object of annotations that are currently being edited.
   * When a user starts editing an annotation, we copy it from `annotations` to `editingAnnotations`.
   * To commit the edits, we copy from `editingAnnotations` back into `annotations`.
   * To discard the edits, we delete from `editingAnnotations`.
   */
  editingAnnotations: {},
  annotations: {},
  pageDimensions: {},
  pdfDocuments: {},
  documentErrors: {},
  text: [],
  documentSearchString: null,
  documentSearchIndex: 0,
  matchIndexToHighlight: null,
  extractedText: {}
};

const reducer = (state = {}, action = {}) => {
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
        ui: {
          tagOptions: {
            $set: uniqueTags
          }
        }
      }
    );
  case Constants.RECEIVE_MANIFESTS:
    return update(state, {
      ui: {
        manifestVbmsFetchedAt: {
          $set: action.payload.manifestVbmsFetchedAt
        },
        manifestVvaFetchedAt: {
          $set: action.payload.manifestVvaFetchedAt
        }
      }
    });
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
    return update(hideErrorMessage(state, 'annotation'), {
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
    return update(showErrorMessage(state, 'annotation', action.payload.errorMessage), {
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
      showErrorMessage(state, 'annotation', action.payload.errorMessage),
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
  case Constants.SET_DOC_SCROLL_POSITION:
    return update(state, {
      ui: {
        pdf: {
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
    return update(state,
      { ui: { pdf: { hidePdfSidebar: { $set: !state.ui.pdf.hidePdfSidebar } } } }
    );
  case Constants.TOGGLE_SEARCH_BAR:
    return update(state,
      { ui: { pdf: { hideSearchBar: { $set: !state.ui.pdf.hideSearchBar } } } }
    );
  case Constants.SHOW_SEARCH_BAR:
    return update(state,
      { ui: { pdf: { hideSearchBar: { $set: false } } } }
    );
  case Constants.HIDE_SEARCH_BAR:
    return update(state,
      { ui: { pdf: { hideSearchBar: { $set: true } } } }
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
  case Constants.SET_UP_PAGE_DIMENSIONS:
    return update(
      state,
      {
        pageDimensions: {
          [`${action.payload.file}-${action.payload.pageIndex}`]: {
            $set: {
              ...action.payload.dimensions,
              file: action.payload.file,
              pageIndex: action.payload.pageIndex
            }
          }
        }
      }
    );
  case Constants.SET_PDF_DOCUMENT:
    return update(
      state,
      {
        pdfDocuments: {
          [action.payload.file]: {
            $set: action.payload.doc
          }
        }
      }
    );
  case Constants.CLEAR_PDF_DOCUMENT:
    if (action.payload.doc && _.get(state.pdfDocuments, [action.payload.file]) === action.payload.doc) {
      return update(
        state,
        {
          pdfDocuments: {
            [action.payload.file]: {
              $set: null
            }
          }
        });
    }

    return state;
  case Constants.SET_DOCUMENT_LOAD_ERROR:
    return update(state, {
      documentErrors: {
        [action.payload.file]: {
          $set: true
        }
      }
    });
  case Constants.CLEAR_DOCUMENT_LOAD_ERROR:
    return update(state, {
      documentErrors: {
        [action.payload.file]: {
          $set: false
        }
      }
    });
  case Constants.GET_DOCUMENT_TEXT:
    return update(
      state,
      {
        extractedText: {
          $merge: action.payload.textObject
        }
      }
    );
  case Constants.ZERO_SEARCH_INDEX:
    return update(
      state,
      {
        documentSearchIndex: {
          $set: 0
        }
      }
    );
  case Constants.UPDATE_SEARCH_INDEX:
    return update(
      state,
      {
        documentSearchIndex: {
          $apply: (index) => action.payload.increment ? index + 1 : index - 1
        }
      }
    );
  case Constants.SET_SEARCH_INDEX:
    return update(
      state,
      {
        documentSearchIndex: {
          $set: action.payload.index
        }
      }
    );
  case Constants.SET_SEARCH_INDEX_TO_HIGHLIGHT:
    return update(
      state,
      {
        matchIndexToHighlight: {
          $set: action.payload.index
        }
      }
    );
  case Constants.SET_LOADED_APPEAL_ID:
    return update(state, {
      loadedAppealId: {
        $set: action.payload.vacolsId
      }
    });

  case Constants.UPDATE_FILTERED_DOC_IDS:
    return updateFilteredDocIds(state);

  // errors
  case Constants.HIDE_ERROR_MESSAGE:
    return hideErrorMessage(state, action.payload.messageType);
  case Constants.SHOW_ERROR_MESSAGE:
    return showErrorMessage(state, action.payload.messageType);
  case Constants.RESET_PDF_SIDEBAR_ERRORS:
    return update(state, {
      ui: {
        pdfSidebar: { error: { $set: initialPdfSidebarErrorState } }
      }
    });
  default:
    return state;
  }
};

export const readerReducer = (state = initialState, action = {}) => ({
  ...reducer(state, action),
  documents: documentsReducer(state.documents, action)
});

export default timeFunction(
  readerReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
