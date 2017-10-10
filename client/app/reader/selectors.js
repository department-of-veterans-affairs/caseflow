import { createSelector } from 'reselect';
import _ from 'lodash';
import { getSearchSelectors } from 'redux-search'

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

const getText = (state) => state.text;

const getTextObject = createSelector([getText], (text) => { return text.reduce(
  (acc, pageText, index) => {
    const concatenated = pageText.items.map((row) => row.str).join(' ');
    const splitWords = concatenated.split(' ');
    splitWords.forEach((word, wordIndex) => {
      const end = Math.min(wordIndex + 5, concatenated.length);
      const begin = Math.max(wordIndex - 5, 0);
      const sentence = splitWords.slice(begin, end).join(' ');
      const after = splitWords.slice(wordIndex + 1, end);
      if (acc[word]) {
        acc[word].push({ index, sentence, after });
      } else {
        acc[word] = [{ index, sentence, after }];
      }
    })
    return acc;
  }, {}
)});

const getSearchTerm = (state) => state.documentSearchString;

export const getTextSnippets = createSelector([getTextObject, getSearchTerm], (textObject, searchTerm) => {
  return Object.keys(textObject).reduce((acc, key) => {
    console.log(key, searchTerm, key.includes(searchTerm));
    if (key.includes(searchTerm)) {
      return acc.concat(textObject[key]);
    }

    return acc;
  }, []);
});

// :text is a selector that returns the text Books are currently filtered by
// :result is an Array of Book ids that match the current seach :text (or all Books if there is no search :text)
const {
  text, // search text
  result // book ids
} = getSearchSelectors({
  resourceName: 'pagesText',
  resourceSelector: (resourceName, state) => state.readerReducer[resourceName]
})

const pagesText = state => state.readerReducer.pagesText;

export const getTextSearch = createSelector(
  [result, pagesText, text],
  (pageIds, pagesText, searchText) => ({
    pageIds,
    pagesText,
    searchText
  })
)