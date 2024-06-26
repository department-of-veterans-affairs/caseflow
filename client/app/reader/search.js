import * as Constants from './constants';
import { categoryFieldNameOfCategoryName } from './utils';
import { makeGetAnnotationsByDocumentId } from './selectors';
import { doDatesMatch } from '../util/DateUtil';
import { compact } from 'lodash';

const typeContainsString = (searchQuery, doc) => {
  return doc.type.toLowerCase().includes(searchQuery);
};

const commentContainsString = (searchQuery, state, doc) =>
  makeGetAnnotationsByDocumentId(state)(doc.id).reduce(
    (acc, annotation) => acc || annotation.comment.toLowerCase().includes(searchQuery),
    false
  );

export const commentContainsWords = (searchQuery, state, doc) => {
  let queryTokens = compact(searchQuery.split(' '));

  return queryTokens.some((word) => {
    return commentContainsString(word, state, doc);
  });
};

const categoryContainsString = (searchQuery, doc) =>
  Object.keys(Constants.documentCategories).reduce(
    (acc, category) => acc || (category.includes(searchQuery) && doc[categoryFieldNameOfCategoryName(category)]),
    false
  );

export const categoryContainsWords = (searchQuery, doc) => {
  let queryTokens = compact(searchQuery.split(' '));

  return Object.keys(Constants.documentCategories).reduce((result, category) => {
    return {
      ...result,
      [`${category}`]: queryTokens.some(
        (word) => category.includes(word) && doc[categoryFieldNameOfCategoryName(category)]
      )
    };
  }, {});
};

const tagContainsString = (searchQuery, doc) =>
  Object.keys(doc.tags || {}).reduce((acc, tag) => {
    return acc || doc.tags[tag].text.toLowerCase().includes(searchQuery);
  }, false);

const descriptionContainsString = (searchQuery, doc) =>
  doc.description && doc.description.toLowerCase().includes(searchQuery);

export const searchString = (searchQuery, state) => (doc) => {
  let queryTokens = compact(searchQuery.split(' '));

  return queryTokens.every((word) => {
    const searchWord = word.trim();

    return (
      searchWord.length > 0 &&
      (doDatesMatch(doc.receivedAt, searchWord) ||
        commentContainsString(word, state, doc) ||
        typeContainsString(searchWord, doc) ||
        categoryContainsString(searchWord, doc) ||
        tagContainsString(searchWord, doc) ||
        descriptionContainsString(searchWord, doc))
    );
  });
};
