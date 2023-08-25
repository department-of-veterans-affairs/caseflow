import { get, pickBy, sortBy, toPairs, map, forEach, some, find, filter } from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';
import { searchString, commentContainsWords, categoryContainsWords } from './search';
import { update } from '../util/ReducerUtil';

export const getUpdatedFilteredResults = (state) => {
  const updatedNextState = update(state, {});
  const documents = update(state.documents, {});
  const searchCategoryHighlights = update(state.documentList.searchCategoryHighlights, {});

  const { docFilterCriteria } = state.documentList;
  const activeCategoryFilters = map(
    filter(toPairs(docFilterCriteria.category), ([key, value]) => value), // eslint-disable-line no-unused-vars
    ([key]) => categoryFieldNameOfCategoryName(key)
  );

  const activeTagFilters = map(
    filter(toPairs(docFilterCriteria.tag), ([key, value]) => value), // eslint-disable-line no-unused-vars
    ([key]) => key
  );

  const activeDocTypeFilter = map(
    filter(toPairs(docFilterCriteria.document), ([key, value]) => value), // eslint-disable-line no-unused-vars
    ([key]) => key
  );

  const searchQuery = get(docFilterCriteria, 'searchQuery', '').toLowerCase();

  // ensure we have a deep clone so we are not mutating the original state
  const filteredIds = map(
    sortBy(
      filter(
        filter(
          filter(
            filter(
              updatedNextState.documents,
              (doc) => !activeDocTypeFilter.length || some(activeDocTypeFilter, (docType) => docType === doc.type)
            ),
            (doc) => !activeCategoryFilters.length ||
              some(activeCategoryFilters, (categoryFieldName) => doc[categoryFieldName])
          ),
          (doc) => !activeTagFilters.length || some(activeTagFilters, (tagText) => find(doc.tags, { text: tagText }))
        ),
        searchString(searchQuery, updatedNextState)),
      docFilterCriteria.sort.sortBy
    ),
    'id'
  );

  // looping through all the documents to update category highlights and expanding comments
  forEach(updatedNextState.documents, (doc) => {
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
