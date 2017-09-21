/* eslint-disable max-lines */

import * as Constants from './constants';
import _ from 'lodash';
import ApiUtil from '../util/ApiUtil';
import uuid from 'uuid';
import { CATEGORIES } from './analytics';

export const collectAllTags = (documents) => ({
  type: Constants.COLLECT_ALL_TAGS_FOR_OPTIONS,
  payload: documents
});

export const onInitialDataLoadingFail = (value = true) => ({
  type: Constants.REQUEST_INITIAL_DATA_FAILURE,
  payload: { value }
});

export const onInitialCaseLoadingFail = (value = true) => ({
  type: Constants.REQUEST_INITIAL_CASE_FAILURE,
  payload: { value }
});

export const onReceiveDocs = (documents, vacolsId) => (
  (dispatch) => {
    dispatch(collectAllTags(documents));
    dispatch({
      type: Constants.RECEIVE_DOCUMENTS,
      payload: {
        documents,
        vacolsId
      }
    });
  }
);

export const onReceiveAnnotations = (annotations) => ({
  type: Constants.RECEIVE_ANNOTATIONS,
  payload: { annotations }
});

export const onReceiveAssignments = (assignments) => ({
  type: Constants.RECEIVE_ASSIGNMENTS,
  payload: { assignments }
});

export const toggleDocumentCategoryFail = (docId, categoryKey, categoryValueToRevertTo) => ({
  type: Constants.TOGGLE_DOCUMENT_CATEGORY_FAIL,
  payload: {
    docId,
    categoryKey,
    categoryValueToRevertTo
  }
});

export const setSearch = (searchQuery) => ({
  type: Constants.SET_SEARCH,
  payload: {
    searchQuery
  },
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'search',
      debounceMs: 500
    }
  }
});

export const setCaseSelectSearch = (searchQuery) => ({
  type: Constants.SET_CASE_SELECT_SEARCH,
  payload: {
    searchQuery
  }
});

export const clearCaseSelectSearch = () => ({
  type: Constants.CLEAR_CASE_SELECT_SEARCH
});

export const setDocListScrollPosition = (scrollTop) => ({
  type: Constants.SET_DOC_LIST_SCROLL_POSITION,
  payload: {
    scrollTop
  }
});

export const toggleDropdownFilterVisibility = (filterName) => ({
  type: Constants.TOGGLE_FILTER_DROPDOWN,
  payload: {
    filterName
  },
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'toggle-dropdown-filter',
      label: filterName
    }
  }
});

export const changeSortState = (sortBy) => ({
  type: Constants.SET_SORT,
  payload: {
    sortBy
  },
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'change-sort-by',
      label: (nextState) => {
        const direction = nextState.readerReducer.ui.docFilterCriteria.sort.sortAscending ? 'ascending' : 'descending';

        return `${sortBy}-${direction}`;
      }
    }
  }
});

export const onScrollToComment = (scrollToComment) => ({
  type: Constants.SCROLL_TO_COMMENT,
  payload: { scrollToComment }
});

export const startEditAnnotation = (annotationId) => ({
  type: Constants.START_EDIT_ANNOTATION,
  payload: {
    annotationId
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'start-edit-annotation'
    }
  }
});

export const openAnnotationDeleteModal = (annotationId, analyticsLabel) => ({
  type: Constants.OPEN_ANNOTATION_DELETE_MODAL,
  payload: {
    annotationId
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'open-annotation-delete-modal',
      label: analyticsLabel
    }
  }
});
export const closeAnnotationDeleteModal = () => ({
  type: Constants.CLOSE_ANNOTATION_DELETE_MODAL,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'close-annotation-delete-modal'
    }
  }
});
export const selectAnnotation = (annotationId) => ({
  type: Constants.SELECT_ANNOTATION,
  payload: {
    annotationId
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'select-annotation'
    }
  }
});

export const deleteAnnotation = (docId, annotationId) =>
  (dispatch) => {
    dispatch({
      type: Constants.REQUEST_DELETE_ANNOTATION,
      payload: {
        annotationId
      },
      meta: {
        analytics: {
          category: CATEGORIES.VIEW_DOCUMENT_PAGE,
          action: 'request-delete-annotation'
        }
      }
    });

    ApiUtil.delete(`/document/${docId}/annotation/${annotationId}`).
      then(
        () => dispatch({
          type: Constants.REQUEST_DELETE_ANNOTATION_SUCCESS,
          payload: {
            annotationId
          }
        }),
        () => dispatch({
          type: Constants.REQUEST_DELETE_ANNOTATION_FAILURE,
          payload: {
            annotationId
          }
        })
      );
  };

export const requestMoveAnnotation = (annotation) => (dispatch) => {
  dispatch({
    type: Constants.REQUEST_MOVE_ANNOTATION,
    payload: {
      annotation
    },
    meta: {
      analytics: {
        category: CATEGORIES.VIEW_DOCUMENT_PAGE,
        action: 'request-move-annotation'
      }
    }
  });

  const data = ApiUtil.convertToSnakeCase({ annotation });

  ApiUtil.patch(`/document/${annotation.documentId}/annotation/${annotation.id}`, { data }).
    then(
      () => dispatch({
        type: Constants.REQUEST_MOVE_ANNOTATION_SUCCESS,
        payload: {
          annotationId: annotation.id
        }
      }),
      () => dispatch({
        type: Constants.REQUEST_MOVE_ANNOTATION_FAILURE,
        payload: {
          annotationId: annotation.id
        }
      })
    );
};

export const cancelEditAnnotation = (annotationId) => ({
  type: Constants.CANCEL_EDIT_ANNOTATION,
  payload: {
    annotationId
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'cancel-edit-annotation'
    }
  }
});
export const updateAnnotationContent = (content, annotationId) => ({
  type: Constants.UPDATE_ANNOTATION_CONTENT,
  payload: {
    annotationId,
    content
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'edit-annotation-content-locally',
      debounceMs: 500
    }
  }
});
export const updateNewAnnotationContent = (content) => ({
  type: Constants.UPDATE_NEW_ANNOTATION_CONTENT,
  payload: {
    content
  }
});

export const jumpToPage = (pageNumber, docId) => ({
  type: Constants.JUMP_TO_PAGE,
  payload: {
    pageNumber,
    docId
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'jump-to-page'
    }
  }
});

export const resetJumpToPage = () => ({
  type: Constants.RESET_JUMP_TO_PAGE
});

export const requestEditAnnotation = (annotation) => (dispatch) => {
  // If the user removed all text content in the annotation, ask them if they're
  // intending to delete it.
  if (!annotation.comment) {
    dispatch(openAnnotationDeleteModal(annotation.id, 'open-by-deleting-all-annotation-content'));

    return;
  }

  dispatch({
    type: Constants.REQUEST_EDIT_ANNOTATION,
    payload: {
      annotationId: annotation.id
    },
    meta: {
      analytics: {
        category: CATEGORIES.VIEW_DOCUMENT_PAGE,
        action: 'request-edit-annotation'
      }
    }
  });

  const data = ApiUtil.convertToSnakeCase({ annotation });

  ApiUtil.patch(`/document/${annotation.documentId}/annotation/${annotation.id}`, { data }).
    then(
      () => dispatch({
        type: Constants.REQUEST_EDIT_ANNOTATION_SUCCESS,
        payload: {
          annotationId: annotation.id
        }
      }),
      () => dispatch({
        type: Constants.REQUEST_EDIT_ANNOTATION_FAILURE,
        payload: {
          annotationId: annotation.id
        }
      })
    );
};

export const startPlacingAnnotation = (interactionType) => ({
  type: Constants.START_PLACING_ANNOTATION,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'start-placing-annotation',
      label: interactionType
    }
  }
});

export const showPlaceAnnotationIcon = (pageIndex, pageCoords) => ({
  type: Constants.SHOW_PLACE_ANNOTATION_ICON,
  payload: {
    pageIndex,
    pageCoords
  }
});

export const placeAnnotation = (pageNumber, coordinates, documentId) => ({
  type: Constants.PLACE_ANNOTATION,
  payload: {
    page: pageNumber,
    x: coordinates.xPosition,
    y: coordinates.yPosition,
    documentId
  }
});

export const stopPlacingAnnotation = (interactionType) => ({
  type: Constants.STOP_PLACING_ANNOTATION,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'stop-placing-annotation',
      label: interactionType
    }
  }
});

export const createAnnotation = (annotation) => (dispatch) => {
  const temporaryId = uuid.v4();

  dispatch({
    type: Constants.REQUEST_CREATE_ANNOTATION,
    payload: {
      annotation: {
        ...annotation,
        id: temporaryId
      }
    }
  });

  const data = ApiUtil.convertToSnakeCase({ annotation });

  ApiUtil.post(`/document/${annotation.documentId}/annotation`, { data }).
    then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: Constants.REQUEST_CREATE_ANNOTATION_SUCCESS,
          payload: {
            annotation: {
              ...annotation,
              ...responseObject
            },
            annotationTemporaryId: temporaryId
          }
        });
      },
      () => dispatch({
        type: Constants.REQUEST_CREATE_ANNOTATION_FAILURE,
        payload: {
          annotationTemporaryId: temporaryId
        }
      })
    );
};

export const handleSelectCommentIcon = (comment) => (dispatch) => {
  // Normally, we would not want to fire two actions here.
  // I think that SCROLL_TO_SIDEBAR_COMMENT needs cleanup
  // more generally, so I'm just going to leave it alone for now,
  // and hack this in here.
  dispatch(selectAnnotation(comment.id));
  dispatch({
    type: Constants.SCROLL_TO_SIDEBAR_COMMENT,
    payload: {
      scrollToSidebarComment: comment
    }
  });
};

export const handleSetLastRead = (docId) => ({
  type: Constants.LAST_READ_DOCUMENT,
  payload: {
    docId
  }
});

export const newTagRequestSuccess = (docId, createdTags) => (
  (dispatch, getState) => {
    dispatch({
      type: Constants.REQUEST_NEW_TAG_CREATION_SUCCESS,
      payload: {
        docId,
        createdTags
      }
    });
    const { documents } = getState().readerReducer;

    dispatch(collectAllTags(documents));
  }
);

export const newTagRequestFailed = (docId, tagsThatWereAttemptedToBeCreated) => ({
  type: Constants.REQUEST_NEW_TAG_CREATION_FAILURE,
  payload: {
    docId,
    tagsThatWereAttemptedToBeCreated
  }
});

export const selectCurrentPdfLocally = (docId) => ({
  type: Constants.SELECT_CURRENT_VIEWER_PDF,
  payload: {
    docId
  }
});

export const selectCurrentPdf = (docId) => (dispatch) => {
  ApiUtil.patch(`/document/${docId}/mark-as-read`).
    catch((err) => {
      // eslint-disable-next-line no-console
      console.log('Error marking as read', docId, err);
    });

  dispatch(
    selectCurrentPdfLocally(docId)
  );
};

export const removeTagRequestFailure = (docId, tagId) => ({
  type: Constants.REQUEST_REMOVE_TAG_FAILURE,
  payload: {
    docId,
    tagId
  }
});

export const removeTagRequestSuccess = (docId, tagId) => (
  (dispatch, getState) => {
    dispatch({
      type: Constants.REQUEST_REMOVE_TAG_SUCCESS,
      payload: {
        docId,
        tagId
      }
    });
    const { documents } = getState().readerReducer;

    dispatch(collectAllTags(documents));
  }
);

export const setTagFilter = (text, checked, tagId) => ({
  type: Constants.SET_TAG_FILTER,
  payload: {
    text,
    checked
  },
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: `${checked ? 'set' : 'unset'}-tag-filter`,
      label: tagId
    }
  }
});

export const setCategoryFilter = (categoryName, checked) => ({
  type: Constants.SET_CATEGORY_FILTER,
  payload: {
    categoryName,
    checked
  },
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: `${checked ? 'select' : 'unselect'}-category-filter`,
      label: categoryName
    }
  }
});

export const clearTagFilters = () => ({
  type: Constants.CLEAR_TAG_FILTER,
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'clear-tag-filters'
    }
  }
});

export const clearCategoryFilters = () => ({
  type: Constants.CLEAR_CATEGORY_FILTER,
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'clear-category-filters'
    }
  }
});

export const clearAllFilters = () => ({
  type: Constants.CLEAR_ALL_FILTERS,
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'clear-all-filters'
    }
  }
});

export const clearSearch = () => ({
  type: Constants.CLEAR_ALL_SEARCH,
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'clear-search'
    }
  }
});

export const removeTag = (doc, tagId) => (
  (dispatch) => {
    dispatch({
      type: Constants.REQUEST_REMOVE_TAG,
      payload: {
        docId: doc.id,
        tagId
      }
    });
    ApiUtil.delete(`/document/${doc.id}/tag/${tagId}`).
      then(() => {
        dispatch(removeTagRequestSuccess(doc.id, tagId));
      }, () => {
        dispatch(removeTagRequestFailure(doc.id, tagId));
      });
  }
);


export const onReceiveAppealDetails = (appeal) => ({
  type: Constants.RECEIVE_APPEAL_DETAILS,
  payload: { appeal }
});

export const onAppealDetailsLoadingFail = (failedToLoad = true) => ({
  type: Constants.RECEIVE_APPEAL_DETAILS_FAILURE,
  payload: { failedToLoad }
});

export const fetchedNoAppealsUsingVeteranId = () => ({
  type: Constants.RECEIVED_NO_APPEALS_USING_VETERAN_ID
});

export const fetchAppealDetails = (vacolsId) => (
  (dispatch) => {
    ApiUtil.get(`/reader/appeal/${vacolsId}?json`).then((response) => {
      const returnedObject = JSON.parse(response.text);

      dispatch(onReceiveAppealDetails(returnedObject.appeal));
    }, () => dispatch(onAppealDetailsLoadingFail()));
  }
);

export const onReceiveAppealsUsingVeteranId = (appeals) => ({
  type: Constants.RECEIVE_APPEALS_USING_VETERAN_ID_SUCCESS,
  payload: { appeals }
});

export const fetchAppealUsingVeteranIdFailed = () => ({
  type: Constants.RECEIVE_APPEALS_USING_VETERAN_ID_FAILURE
});

export const caseSelectAppeal = (appeal) => ({
  type: Constants.CASE_SELECT_APPEAL,
  payload: { appeal }
});

export const requestAppealUsingVeteranId = () => ({
  type: Constants.REQUEST_APPEAL_USING_VETERAN_ID,
  meta: {
    analytics: {
      category: CATEGORIES.CASE_SELECTION_PAGE,
      action: 'case-search'
    }
  }
});

export const fetchAppealUsingVeteranId = (veteranId) => (
  (dispatch) => {
    dispatch(requestAppealUsingVeteranId());
    ApiUtil.get('/reader/appeal/veteran-id?json', {
      headers: { 'veteran-id': veteranId } }).
    then((response) => {
      const returnedObject = JSON.parse(response.text);

      if (_.size(returnedObject.appeals) === 0) {
        dispatch(fetchedNoAppealsUsingVeteranId());
      } else {
        dispatch(onReceiveAppealsUsingVeteranId(returnedObject.appeals));
      }
    }, () => dispatch(fetchAppealUsingVeteranIdFailed()));
  }
);

export const addNewTag = (doc, tags) => (
  (dispatch) => {
    const currentTags = doc.tags;

    const newTags = _(tags).
      differenceWith(currentTags, (tag, currentTag) => tag.value === currentTag.text).
      map((tag) => ({ text: tag.label })).
      value();

    if (_.size(newTags)) {
      dispatch({
        type: Constants.REQUEST_NEW_TAG_CREATION,
        payload: {
          newTags,
          docId: doc.id
        }
      });
      ApiUtil.post(`/document/${doc.id}/tag`, { data: { tags: newTags } }).
        then((data) => {
          dispatch(newTagRequestSuccess(doc.id, data.body.tags));
        }, () => {
          dispatch(newTagRequestFailed(doc.id, newTags));
        });
    }
  }
);

export const setOpenedAccordionSections = (openedAccordionSections, prevSections) => ({
  type: Constants.SET_OPENED_ACCORDION_SECTIONS,
  payload: {
    openedAccordionSections
  },
  meta: {
    analytics: (triggerEvent) => {
      const addedSectionKeys = _.difference(openedAccordionSections, prevSections);
      const removedSectionKeys = _.difference(prevSections, openedAccordionSections);

      addedSectionKeys.forEach(
        (newKey) => triggerEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'opened-accordion-section', newKey)
      );
      removedSectionKeys.forEach(
        (oldKey) => triggerEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'closed-accordion-section', oldKey)
      );
    }
  }
});

export const setViewingDocumentsOrComments = (documentsOrComments) => ({
  type: Constants.SET_VIEWING_DOCUMENTS_OR_COMMENTS,
  payload: {
    documentsOrComments
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'set-viewing-documents-or-comments',
      label: documentsOrComments
    }
  }
});

export const togglePdfSidebar = () => ({
  type: Constants.TOGGLE_PDF_SIDEBAR,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'toggle-pdf-sidebar',
      label: (nextState) => nextState.readerReducer.ui.pdf.hidePdfSidebar ? 'hide' : 'show'
    }
  }
});


export const handleToggleCommentOpened = (docId) => ({
  type: Constants.TOGGLE_COMMENT_LIST,
  payload: {
    docId
  },
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'toggle-comment-list',
      label: (nextState) => nextState.readerReducer.documents[docId].listComments ? 'open' : 'close'
    }
  }
});

export const caseSelectModalSelectVacolsId = (vacolsId) => ({
  type: Constants.CASE_SELECT_MODAL_APPEAL_VACOLS_ID,
  payload: {
    vacolsId
  }
});

export const setUpPdfPage = (file, pageIndex, page) => ({
  type: Constants.SET_UP_PDF_PAGE,
  payload: {
    file,
    pageIndex,
    page
  }
});

export const clearPdfPage = (file, pageIndex, page) => ({
  type: Constants.CLEAR_PDF_PAGE,
  payload: {
    file,
    pageIndex,
    page
  }
});

export const setPdfDocument = (file, doc) => ({
  type: Constants.SET_PDF_DOCUMENT,
  payload: {
    file,
    doc
  }
});
