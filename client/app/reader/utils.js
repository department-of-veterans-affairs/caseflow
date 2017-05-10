import _ from 'lodash';

export const categoryFieldNameOfCategoryName =
    (categoryName) => `category_${categoryName}`;

export const keyOfAnnotation = ({ x, y, page, documentId }) => [x, y, page, documentId].join('-');

export const getAnnotationByDocumentId = (state, docId) =>
  _(state.editingAnnotations).
  values().
  map((annotation) => ({
    editing: true,
    ...annotation
  })).
  concat(_.values(state.annotations), state.ui.pendingAnnotation).
  uniqBy('id').
  filter({ documentId: docId }).
  value();

export const sortAnnotations = (annotations) =>
  _(annotations).
    sortBy('page', 'y').
    compact().
    value();
