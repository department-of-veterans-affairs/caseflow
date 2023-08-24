import { createSelector } from 'reselect';
import { keyBy, memoize, reject, sum, uniqBy, map, mapValues, filter, size, values, some } from 'lodash';

const getFilteredDocIds = (state) => state.documentList.filteredDocIds;
const getAllDocs = (state) => state.documents;

export const getFilteredDocuments = createSelector(
  [getFilteredDocIds, getAllDocs],
  // eslint-disable-next-line no-confusing-arrow
  (filteredDocIds, allDocs) =>
    filteredDocIds ?
      map(filteredDocIds, (docId) => allDocs[docId]) :
      values(allDocs)
);

const getEditingAnnotations = (state) => state.annotationLayer.editingAnnotations;
const getPendingEditingAnnotations = (state) => state.annotationLayer.pendingEditingAnnotations;
const getAnnotations = (state) => state.annotationLayer.annotations;
const getPendingAnnotations = (state) => state.annotationLayer.pendingAnnotations;

export const makeGetAnnotationsByDocumentId = createSelector(
  [getEditingAnnotations, getPendingEditingAnnotations, getAnnotations, getPendingAnnotations],
  (editingAnnotations, pendingEditingAnnotations, annotations, pendingAnnotations) =>
    memoize((docId) =>
      reject(
        uniqBy(
          values(editingAnnotations).
            map((annotation) => ({
              editing: true,
              ...annotation
            })).
            concat(
              values(pendingEditingAnnotations),
              values(annotations),
              values(pendingAnnotations)
            ),
          'id'
        ),
        'pendingDeletion'
      ).filter((doc) => doc.documentId === docId)
    )
);

export const getAnnotationsPerDocument = createSelector(
  [getFilteredDocuments, makeGetAnnotationsByDocumentId],
  (documents, getAnnotationsByDocumentId) =>
    mapValues(keyBy(documents, 'id'), (doc) => getAnnotationsByDocumentId(doc.id))
);

const getDocFilterCriteria = (state) => state.documentList.docFilterCriteria;

/* eslint-disable newline-per-chained-call */

export const docListIsFiltered = createSelector(
  [getAllDocs, getFilteredDocIds, getDocFilterCriteria],
  (documents, filteredDocIds, docFilterCriteria) =>
    Boolean(
      size(documents) !== filteredDocIds.length ||
        docFilterCriteria.searchQuery ||
        some(values(docFilterCriteria.category)) ||
        some(values(docFilterCriteria.tag)) ||
        some(values(docFilterCriteria.document))
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
  (extractedText, file) => filter(extractedText, (pageText) => pageText.file === file)
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

    return textForFile.
      map((page) => ({
        id: page.id,
        pageIndex: page.pageIndex,
        matches: (page.text.match(regex) || []).length
      })).
      filter((page) => {
        return page.matches > 0;
      });
  }
);

export const getTotalMatchesInFile = createSelector(
  [getMatchesPerPageInFile],
  (matches) => sum(map(matches, (match) => match.matches))
);

const getSelectedIndex = (state) => state.searchActionReducer.matchIndex;

export const getCurrentMatchIndex = createSelector(
  [getTotalMatchesInFile, getSelectedIndex],
  (totalMatchesInFile, selectedIndex) => (selectedIndex + totalMatchesInFile) % totalMatchesInFile
);
