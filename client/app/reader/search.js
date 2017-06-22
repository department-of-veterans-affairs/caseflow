import * as Constants from './constants';
import { categoryFieldNameOfCategoryName } from './utils';
import { makeGetAnnotationsByDocumentId } from './selectors';
import { doDatesMatch } from '../util/DateUtil';
import _ from 'lodash';

const typeContainsString = (searchQuery, doc) => {
  return (doc.type.toLowerCase().includes(searchQuery));
};

const commentContainsString = (searchQuery, state, doc) =>
  makeGetAnnotationsByDocumentId(state)(doc.id).reduce((acc, annotation) =>
    acc || annotation.comment.toLowerCase().includes(searchQuery)
  , false);

const categoryContainsString = (searchQuery, doc) =>
  Object.keys(Constants.documentCategories).reduce((acc, category) =>
    acc || (category.includes(searchQuery) &&
      doc[categoryFieldNameOfCategoryName(category)])
  , false);

const tagContainsString = (searchQuery, doc) =>
  Object.keys(doc.tags || {}).reduce((acc, tag) => {
    return acc || (doc.tags[tag].text.toLowerCase().includes(searchQuery));
  }
  , false);

export const searchString = (searchQuery, state) => (doc) => {

  let queryTokens = _.compact(searchQuery.split(' '));
  const dateMatch = doDatesMatch(doc.receivedAt, queryTokens[0]);

  // if date matched using the first element, remove the
  // first element from the list.
  if (dateMatch) {
    queryTokens.shift();
  }

  const stringSearchResult = queryTokens.every((word) => {
    const searchWord = word.trim();

    return searchWord.length > 0 && (
      typeContainsString(searchWord, doc) ||
      categoryContainsString(searchWord, doc) ||
      commentContainsString(searchWord, state, doc) ||
      tagContainsString(searchWord, doc));
  });

  if (dateMatch) {
    return (stringSearchResult && dateMatch);
  }

  return stringSearchResult;
};
