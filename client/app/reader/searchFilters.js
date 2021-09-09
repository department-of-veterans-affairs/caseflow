import { get, pickBy, sortBy, toPairs } from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';
import { searchString, commentContainsWords, categoryContainsWords } from './search';
import { update } from '../util/ReducerUtil';

export const getUpdatedFilteredResults = (state) => {
  const updatedNextState = update(state, {});
  const documents = update(state.documents, {});
  const searchCategoryHighlights = update(state.documentList.searchCategoryHighlights, {});

  const { docFilterCriteria } = state.documentList;
  const activeCategoryFilters = toPairs(docFilterCriteria.category).
    filter(([key, value]) => value). // eslint-disable-line no-unused-vars
    map(([key]) => categoryFieldNameOfCategoryName(key));

  const activeTagFilters = toPairs(docFilterCriteria.tag).
    filter(([key, value]) => value). // eslint-disable-line no-unused-vars
    map(([key]) => key);

  const searchQuery = get(docFilterCriteria, 'searchQuery', '').toLowerCase();

  // ensure we have a deep clone so we are not mutating the original state

  const filteredIds = sortBy(
    updatedNextState.documents.
      filter(
        (doc) => !activeCategoryFilters.length || activeCategoryFilters.some((categoryFieldName) => doc[categoryFieldName])
      ).
      filter(
        (doc) => !activeTagFilters.length || activeTagFilters.some((tagText) => doc.tags.find((tag) => tag.text === tagText))
      ).
      filter(searchString(searchQuery, updatedNextState)),
    docFilterCriteria.sort.sortBy
  ).map((doc) => doc.id);

  // looping through all the documents to update category highlights and expanding comments
  updatedNextState.documents.forEach((doc) => {
    const containsWords = commentContainsWords(searchQuery, updatedNextState, doc);

    // getting all the truthy values from the object
    // {'medical': true, 'procedural': false } turns into {'medical': true}
    const matchesCategories = pickBy(categoryContainsWords(searchQuery, doc));

    // update the state for all the search category highlights
    if (matchesCategories !== updatedNextState.documentList.searchCategoryHighlights[doc.id]) {
      searchCategoryHighlights[doc.id] = matchesCategories;
    }

    // updating the state of all annotations for expanded comments
    if (containsWords !== doc.listComments) {
      documents[doc.id].listComments = containsWords;
    }
  });

  if (docFilterCriteria.sort.sortAscending) {
    filteredIds.reverse();
  }

  return {
    filteredIds,
    documents,
    searchCategoryHighlights
  };
};
