import _ from 'lodash';
import { newContext } from 'immutability-helper';

export const update = newContext();

update.extend('$unset', (keyToUnset, obj) => obj && _.omit(obj, keyToUnset));

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
  reject('pendingDeletion').
  filter({ documentId: docId }).
  value();

const immutabilityHelperSpecOfPath = (objPath, spec, specVal) =>
  objPath.length ? 
    ({[objPath[0]]: immutabilityHelperSpecOfPath(objPath.slice(1), spec, specVal)}) :
    ({[spec]: specVal})

export const moveModel = (state, srcPath, destPath, id) => 
  update(
    state, 
    {
      ...immutabilityHelperSpecOfPath(srcPath, '$unset', id),    
      ...immutabilityHelperSpecOfPath([...destPath, id], '$set', _.get(state, [...srcPath, id]))
    }
  );

export const sortAnnotations = (annotations) =>
  _(annotations).
    sortBy('page', 'y').
    compact().
    value();
