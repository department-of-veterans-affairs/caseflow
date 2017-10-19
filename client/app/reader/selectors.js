import { createSelector } from 'reselect';
import _ from 'lodash';

const getFilteredDocIds = (state) => state.ui.filteredDocIds;
const getAllDocs = (state) => state.documents;

export const getFilteredDocuments = createSelector(
  [getFilteredDocIds, getAllDocs],
  // eslint-disable-next-line no-confusing-arrow
  (filteredDocIds, allDocs) => filteredDocIds ?
    _.map(filteredDocIds, (docId) => allDocs[docId]) :
    _.values(allDocs)
);

const getEditingAnnotations = (state) => state.editingAnnotations;
const getPendingEditingAnnotations = (state) => state.ui.pendingEditingAnnotations;
const getAnnotations = (state) => state.annotations;
const getPendingAnnotations = (state) => state.ui.pendingAnnotations;

export const makeGetAnnotationsByDocumentId = createSelector(
  [getEditingAnnotations, getPendingEditingAnnotations, getAnnotations, getPendingAnnotations],
  (editingAnnotations, pendingEditingAnnotations, annotations, pendingAnnotations) =>
    _.memoize(
      (docId) =>
        _(editingAnnotations).
          values().
          map((annotation) => ({
            editing: true,
            ...annotation
          })).
          concat(
            _.values(pendingEditingAnnotations),
            _.values(annotations),
            _.values(pendingAnnotations),
          ).
          uniqBy('id').
          reject('pendingDeletion').
          filter({ documentId: docId }).
          value()
    )
);

export const getAnnotationsPerDocument = createSelector(
  [getFilteredDocuments, makeGetAnnotationsByDocumentId],
  (documents, getAnnotationsByDocumentId) =>
    _(documents).
      keyBy('id').
      mapValues((doc) => getAnnotationsByDocumentId(doc.id)).
      value()
);

const getDocFilterCriteria = (state) => state.ui.docFilterCriteria;

/* eslint-disable newline-per-chained-call */

export const docListIsFiltered = createSelector(
  [getAllDocs, getFilteredDocIds, getDocFilterCriteria],
  (documents, filteredDocIds, docFilterCriteria) =>
    Boolean(
      _.size(documents) !== filteredDocIds.length ||
        docFilterCriteria.searchQuery ||
        _(docFilterCriteria.category).values().some() ||
        _(docFilterCriteria.tag).values().some()
    )
);

/* eslint-enable newline-per-chained-call */
