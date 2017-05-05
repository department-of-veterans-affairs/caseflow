import * as Constants from './constants';
import { categoryFieldNameOfCategoryName } from './utils';
import { getAnnotationByDocumentId } from './util/AnnotationUtil';

const metadataContainsString = (searchQuery, doc) =>
  doc.type.toLowerCase().includes(searchQuery) ||
  doc.receivedAt.toLowerCase().includes(searchQuery);

const commentContainsString = (searchQuery, state, doc) =>
  getAnnotationByDocumentId(state, doc.id).reduce((acc, annotation) =>
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

export const searchString = (searchQuery, state) => (doc) =>
  !searchQuery || searchQuery.split(' ').some((searchWord) => {
    return searchWord.length > 0 && (
      metadataContainsString(searchWord, doc) ||
      categoryContainsString(searchWord, doc) ||
      commentContainsString(searchWord, state, doc) ||
      tagContainsString(searchWord, doc));
  });
