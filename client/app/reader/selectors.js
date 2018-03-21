import { createSelector } from 'reselect';
import _ from 'lodash';

const getFilteredDocIds = (state) => state.documentList.filteredDocIds;
const getAllDocs = (state) => state.documents;

export const getFilteredDocuments = createSelector(
  [getFilteredDocIds, getAllDocs],
  // eslint-disable-next-line no-confusing-arrow
  (filteredDocIds, allDocs) => filteredDocIds ?
    _.map(filteredDocIds, (docId) => allDocs[docId]) :
    _.values(allDocs)
);

const getEditingAnnotations = (state) => state.annotationLayer.editingAnnotations;
const getPendingEditingAnnotations = (state) => state.annotationLayer.pendingEditingAnnotations;
const getAnnotations = (state) => state.annotationLayer.annotations;
const getPendingAnnotations = (state) => state.annotationLayer.pendingAnnotations;

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

const getDocFilterCriteria = (state) => state.documentList.docFilterCriteria;

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

// text is a selector that returns the text Pages are currently filtered by
// result is an Array of Page ids that match the current search :text
export const getSearchTerm = (state) => state.searchActionReducer.searchTerm;
const getExtractedText = (state) => state.searchActionReducer.extractedText;
const getFile = (state, props) => props.file;

export const getTextForFile = createSelector(
  [getExtractedText, getFile],
  (extractedText, file) => _.filter(extractedText, (pageText) => pageText.file === file)
);

export const getMatchesPerPageInFile = createSelector(
  [getTextForFile, getSearchTerm],
  (textForFile, searchTerm) => {
    // This function copied from here:
    // https://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
    const escapeRegExp = (str) => {
      return str ? str.replace(/[-[\]/{}()*+?.\\^$|]/g, '\\$&') : null;
    };

    const regex = new RegExp(escapeRegExp(searchTerm), 'gi');

    return textForFile.map((page) => ({
      id: page.id,
      pageIndex: page.pageIndex,
      matches: (page.text.match(regex) || []).length
    })).filter((page) => {
      return page.matches > 0;
    });
  }
);

export const getTotalMatchesInFile = createSelector(
  [getMatchesPerPageInFile],
  (matches) => _(matches).
    map((match) => match.matches).
    sum()
);

const getSelectedIndex = (state) => state.searchActionReducer.matchIndex;

export const getCurrentMatchIndex = createSelector(
  [getTotalMatchesInFile, getSelectedIndex],
  (totalMatchesInFile, selectedIndex) => (selectedIndex + totalMatchesInFile) % totalMatchesInFile
);
