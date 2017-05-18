import { createSelector } from 'reselect';
import _ from 'lodash';

const getFilteredDocIds = (state) => state.ui.filteredDocIds;
const getAllDocs = (state) => state.documents;

export const getFilteredDocuments = createSelector(
  [getFilteredDocIds, getAllDocs],
  (filteredDocIds, allDocs) => filteredDocIds ?
      _.map(filteredDocIds, (docId) => allDocs[docId]) :
      _.values(allDocs)
);
