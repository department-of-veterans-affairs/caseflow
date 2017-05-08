// TODO Merge this with ../utils.js

import _ from 'lodash';

// TODO rename this to getAnnotation*s*
export const getAnnotationByDocumentId = (state, docId) => 
  _(state.annotations).
    values().
    concat(state.ui.pendingAnnotation).
    filter({ documentId: docId }).
    value();

export const sortAnnotations = (annotations) => 
  _(annotations).
    sortBy('page', 'y').
    compact().
    value();
