import _ from 'lodash';

export const categoryFieldNameOfCategoryName =
    (categoryName) => `category_${categoryName}`;

export const keyOfAnnotation = ({ temporaryId, id }) => temporaryId || id;

export const getAnnotationByDocumentId = (state, docId) =>
  _(state.editingAnnotations).
  values().
  map((annotation) => ({
    editing: true,
    ...annotation
  })).
  concat(
    _.values(state.annotations), 
    _.values(state.ui.pendingAnnotations), 
    _.values(state.ui.pendingEditingAnnotations)
  ).
  uniqBy('id').
  filter({ documentId: docId }).
  value();

export const sortAnnotations = (annotations) =>
  _(annotations).
    sortBy('page', 'y').
    compact().
    value();
