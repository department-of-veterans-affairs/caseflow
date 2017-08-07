import _ from 'lodash';
import { newContext } from 'immutability-helper';
import React from 'react';

export const update = newContext();

update.extend('$unset', (keyToUnset, obj) => obj && _.omit(obj, keyToUnset));

export const singleDocumentLink = (basePath, doc) => {
  let id = doc.id;
  let filename = doc.filename;
  let type = doc.type;
  let receivedAt = doc.receivedAt;

  return `${basePath}/${id}?type=${type}` +
    `&received_at=${receivedAt}&filename=${filename}`;
};

export const categoryFieldNameOfCategoryName =
  (categoryName) => `category_${categoryName}`;

export const keyOfAnnotation = ({ temporaryId, id }) => temporaryId || id;

/**
 * immutability-helper takes two arguments: an object and a spec for how to change it:
 *
 *    const spec = { ui: { isEditing: { $set: true } } };
 *    update(state, spec)
 *
 * This is a helper method that generates those specs based on an object path. For the
 * above example, it would be:
 *
 *    const spec = immutabilityHelperSpecOfPath(['ui', 'isEditing'], '$set', true)
 */
const immutabilityHelperSpecOfPath = (objPath, spec, specVal) => {
  // eslint-disable-next-line no-shadow
  const immutabilityHelperSpecOfPathRec = (objPath) => {
    if (!objPath.length) {
      return { [spec]: specVal };
    }

    return { [objPath[0]]: immutabilityHelperSpecOfPath(objPath.slice(1), spec, specVal) };
  };

  return immutabilityHelperSpecOfPathRec(objPath);
};

/**
 * Some parts of our redux state are collections of models, such as:
 *
 *    {
 *      annotations: {},
 *      editingAnnotations: {},
 *      pendingAnnotations: {}
 *    }
 *
 * We move models between those collections to represent their current status.
 * For example, when the server confirms that we saved an annotation, we'd move
 * it from `pendingAnnotations` to `annotations`. This method simplifies doing that.
 * For example usage, see the reducer and the tests.
 */
export const moveModel = (state, srcPath, destPath, id) =>
  update(
    state,
    {
      ...immutabilityHelperSpecOfPath(srcPath, '$unset', id),
      ...immutabilityHelperSpecOfPath([...destPath, id], '$set', _.get(state, [...srcPath, id]))
    }
  );

export const isValidWholeNumber = (number) => {
  return !isNaN(number) && number % 1 === 0;
};

export const sortAnnotations = (annotations) =>
  _(annotations).
    sortBy('page', 'y').
    compact().
    value();

export const isUserEditingText = () => _.some(
  document.querySelectorAll('input,textarea'),
  (elem) => document.activeElement === elem
);

export const getClaimTypeDetailInfo = (claim) => {
  let appealTypeInfo = '';

  if (claim.cavc && claim.aod) {
    appealTypeInfo = 'AOD, CAVC';
  } else if (claim.cavc) {
    appealTypeInfo = 'CAVC';
  } else if (claim.aod) {
    appealTypeInfo = 'AOD';
  }

  return <span className="claim-detail-type-info">{appealTypeInfo}</span>;
};

export const getAppealIfItDoesNotExist = (component) => {
  if (_.isEmpty(component.props.appeal) ||
    (component.props.appeal.vacols_id !== component.props.match.params.vacolsId)) {
    component.props.fetchAppealDetails(component.props.match.params.vacolsId);
  }
};
