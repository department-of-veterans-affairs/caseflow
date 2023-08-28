import { get, pickBy, sortBy, toPairs, map, forEach, some, find, filter } from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';
import { searchString, commentContainsWords, categoryContainsWords } from './search';
import { update } from '../util/ReducerUtil';

// In order to filter by reciept date, we have to handle 4 different scenarios.
// It can be filtered between two dates, before a date, after a date, and on a date.
// this switch takes the filterType stored in redux as a number 0-4, and runs the required
// validation on it, then returns the result.
const filterDates = (docDate, validationDates, filterType) => {

  const FILTER_TYPES = {
    BETWEEN: 0,
    BEFORE: 1,
    AFTER: 2,
    ON: 3
  };
  const beforeDate = (validationDates.beforeDate);
  const afterDate = (validationDates.afterDate);
  const onDate = (validationDates.onDate);

  let validDate = false;

  switch (filterType) {
  case FILTER_TYPES.BETWEEN:
    if (docDate <= beforeDate && docDate >= afterDate) {
      validDate = true;
    }
    break;
  case FILTER_TYPES.BEFORE:
    if (docDate <= beforeDate) {
      validDate = true;
    }
    break;
  case FILTER_TYPES.AFTER:
    if (docDate >= afterDate) {
      validDate = true;
    }
    break;
  case FILTER_TYPES.ON:
    if (docDate === onDate) {
      validDate = true;
    }
    break;
  default:
    validDate = false;
  }

  return validDate;
};

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

  const activeRecieptFilters = map(
    filter(toPairs(docFilterCriteria.recieptFilterDates), ([key, value]) => // eslint-disable-line no-unused-vars
      value),
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

              (doc) => !activeRecieptFilters.length || some(activeRecieptFilters, () =>
                (filterDates(doc.receivedAt, docFilterCriteria.recieptFilterDates,
                  docFilterCriteria.recieptFilterType)))
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
