// TODO Merge this with ../utils.js

import _ from 'lodash';

// TODO rename this to getAnnotation*s*
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
