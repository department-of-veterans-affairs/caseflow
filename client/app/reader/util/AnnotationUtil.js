// TODO Merge this with ../utils.js

import _ from 'lodash';

export const getAnnotationByDocumentId = (annotations, docId) => annotations[docId] || [];

export const sortAnnotations = (annotations) => _(annotations).
  sortBy('page', 'y').
  compact().
  value();
