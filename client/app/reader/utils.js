import _ from 'lodash';
import { newContext } from 'immutability-helper';

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

export const update = newContext();

update.extend('$unset', (keyToUnset, obj) => _.omit(obj, keyToUnset));
