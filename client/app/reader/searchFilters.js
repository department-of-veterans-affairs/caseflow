import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';
import { searchString, commentContainsWords, categoryContainsWords } from './search';
import { update } from '../util/ReducerUtil';

export const updateFilteredDocIds = (state) => {
  const updatedNextState = update(state, {});
  const documents = update(state.documents, {});
  const searchCategoryHighlights = update(state.ui.searchCategoryHighlights, {});

  const { docFilterCriteria } = state.ui;
  const activeCategoryFilters = _(docFilterCriteria.category).
    toPairs().
    filter(([key, value]) => value). // eslint-disable-line no-unused-vars
    map(([key]) => categoryFieldNameOfCategoryName(key)).
    value();

  const activeTagFilters = _(docFilterCriteria.tag).
    toPairs().
    filter(([key, value]) => value). // eslint-disable-line no-unused-vars
    map(([key]) => key).
    value();

  const searchQuery = _.get(docFilterCriteria, 'searchQuery', '').toLowerCase();

  // ensure we have a deep clone so we are not mutating the original state

  const filteredIds = _(updatedNextState.documents).
    filter(
      (doc) => !activeCategoryFilters.length ||
        _.some(activeCategoryFilters, (categoryFieldName) => doc[categoryFieldName])
    ).
    filter(
      (doc) => !activeTagFilters.length ||
        _.some(activeTagFilters, (tagText) => _.find(doc.tags, { text: tagText }))
    ).
    filter(
      searchString(searchQuery, updatedNextState)
    ).
    sortBy(docFilterCriteria.sort.sortBy).
    map('id').
    value();

  // looping through all the documents to update category highlights and expanding comments
  _.forEach(updatedNextState.documents, (doc) => {
    const containsWords = commentContainsWords(searchQuery, updatedNextState, doc);

    // getting all the truthy values from the object
    // {'medical': true, 'procedural': false } turns into {'medical': true}
  const matchesCategories = _.pickBy(categoryContainsWords(searchQuery, doc));

    // update the state for all the search category highlights
    if (matchesCategories !== updatedNextState.ui.searchCategoryHighlights[doc.id]) {
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
