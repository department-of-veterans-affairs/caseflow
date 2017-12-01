import _ from 'lodash';
import React from 'react';
import { ANNOTATION_ICON_SIDE_LENGTH } from '../reader/constants';
import { update } from '../util/ReducerUtil';

export const categoryFieldNameOfCategoryName =
  (categoryName) => `category_${categoryName}`;

export const keyOfAnnotation = ({ temporaryId, id }) => temporaryId || id;

export const pageNumberOfPageIndex = (pageIndex) => pageIndex + 1;
export const pageIndexOfPageNumber = (pageNumber) => pageNumber - 1;

export const pageCoordsOfRootCoords = ({ x, y }, pageBoundingBox, scale) => ({
  x: (x - pageBoundingBox.left) / scale,
  y: (y - pageBoundingBox.top) / scale
});

export const rotateCoordinates = ({ x, y }, container, rotation) => {
  if (rotation === 0) {
    return { x,
      y };
  } else if (rotation === 90) {
    return { x: y,
      y: container.width - x };
  } else if (rotation === 180) {
    return { x: container.width - x,
      y: container.height - y };
  } else if (rotation === 270) {
    return { x: container.height - y,
      y: x };
  }

  return {
    x,
    y
  };
};

export const getPageCoordinatesOfMouseEvent = (event, container, scale, rotation) => {
  const constrainedRootCoords = {
    x: _.clamp(event.pageX, container.left, container.right - ANNOTATION_ICON_SIDE_LENGTH),
    y: _.clamp(event.pageY, container.top, container.bottom - ANNOTATION_ICON_SIDE_LENGTH)
  };

  return rotateCoordinates(pageCoordsOfRootCoords(constrainedRootCoords, container, scale), container, rotation);
};

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

export const shouldFetchAppeal = (appeal, vacolsIdFromUrl) => (_.isEmpty(appeal) ||
    (appeal.vacols_id !== vacolsIdFromUrl));
