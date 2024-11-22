import { createSelector } from 'reselect';

export const appealSelector = (state) => state.pdfViewer.loadedAppeal;

export const categorySelector = (state) => state.pdfViewer.categorySelector;

export const tagSelector = (state) => state.pdfViewer.tagOptions;
export const tagErrorSelector = (state) => state.pdfViewer.pdfSideBarError?.tag;

export const commentErrorSelector = (state) => state.pdfViewer.pdfSideBarError?.annotation;
export const annotationsForDocumentId = createSelector(
  (state) => state.annotationLayer.annotations,
  (_state, documentId) => documentId,
  (annotations, documentId) => Object.values(annotations).filter((annotation) => annotation.documentId === documentId)
);
export const annotationsForDocumentIdAndPageId = createSelector(
  annotationsForDocumentId,
  (_state, _documentId, pageId) => pageId,
  (annotations, pageId) => Object.values(annotations).filter((annotation) => annotation.page === pageId)
);
export const annotationPlacement = (state) => ({
  placedButUnsavedAnnotation: state.annotationLayer.placedButUnsavedAnnotation,
  isPlacingAnnotation: state.annotationLayer.isPlacingAnnotation,
  selectedAnnotationId: state.annotationLayer.selectedAnnotationId,
  placingAnnotationIconPageCoords: state.annotationLayer.placingAnnotationIconPageCoords,
});
export const editingAnnotationsSelector = (state) => Object.values(state.annotationLayer.editingAnnotations);

export const openedAccordionSectionsSelector = (state) => state.pdfViewer.openedAccordionSections;
export const modalInfoSelector = (state) => ({
  deleteAnnotationModalIsOpenFor: state.annotationLayer.deleteAnnotationModalIsOpenFor,
  shareAnnotationModalIsOpenFor: state.annotationLayer.shareAnnotationModalIsOpenFor,
});

export const showSideBarSelector = (state) => !state.pdfViewer.hidePdfSidebar;
export const documentLoadErrorsSelector = (state) => state.pdf.documentErrors;
