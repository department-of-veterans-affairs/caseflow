// TODO Merge this with ../utils.js

import _ from 'lodash';

// TODO rename this to getAnnotation*s*
export const getAnnotationByDocumentId = (state, docId) => {
  let allAnnotations = _.get(state.annotations, docId, []);

  if (_.get(state.ui.pendingAnnotation, 'documentId') === docId) {
    allAnnotations = allAnnotations.concat([state.ui.pendingAnnotation]);
  }

  return allAnnotations;
};

export const sortAnnotations = (annotations) => _(annotations).
  sortBy('page', 'y').
  compact().
  value();
