import _ from 'lodash';
import { newContext } from 'immutability-helper';
import React from 'react';
import { ANNOTATION_ICON_SIDE_LENGTH } from '../reader/constants';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

export const update = newContext();

update.extend('$unset', (keyToUnset, obj) => obj && _.omit(obj, keyToUnset));

export const categoryFieldNameOfCategoryName =
  (categoryName) => `category_${categoryName}`;

export const keyOfAnnotation = ({ temporaryId, id }) => temporaryId || id;

export const pageNumberOfPageIndex = (pageIndex) => pageIndex + 1;
export const pageIndexOfPageNumber = (pageNumber) => pageNumber - 1;

export const pageCoordsOfRootCoords = ({ x, y }, pageBoundingBox, scale) => ({
  x: (x - pageBoundingBox.left) / scale,
  y: (y - pageBoundingBox.top) / scale
});

export const getPageCoordinatesOfMouseEvent = (event, container, scale) => {
  const constrainedRootCoords = {
    x: _.clamp(event.pageX, container.left, container.right - ANNOTATION_ICON_SIDE_LENGTH),
    y: _.clamp(event.pageY, container.top, container.bottom - ANNOTATION_ICON_SIDE_LENGTH)
  };

  return pageCoordsOfRootCoords(constrainedRootCoords, container, scale);
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

let priorityQueue = {};
let isDrawing = false;

export const updatePriority = (id, priority) => {
  if (priorityQueue[id]) {
    priorityQueue[id].priority = priority;
  }
}

export const drawPdfPage = (pdfPage, priority, id, parameters, promiseCallback) => {
  const finishDrawing = () => {
    isDrawing = false;

    const nextToRender = _.reduce(priorityQueue, (acc, entry) => {
      if (acc.priority < entry.priority) {
        return acc;
      } else {
        return entry;
      }
    }, {priority: Number.MAX_SAFE_INTEGER});

    if (nextToRender.priority === Number.MAX_SAFE_INTEGER) {
      return;
    }
    console.log('about to draw...', nextToRender);
    delete priorityQueue[nextToRender.id];
    drawPdfPage(nextToRender.pdfPage, nextToRender.priority, nextToRender.id, nextToRender.parameters, nextToRender.promiseCallback);
  }

  if (!isDrawing) {
    isDrawing = true;
    console.log('Actually drawing', id);

    return pdfPage.render(parameters).then(() => {
      finishDrawing();

      if (promiseCallback) {
        promiseCallback.resolve();
      } else {
        return Promise.resolve();
      }
    }).catch(() => {
      finishDrawing();

      if (promiseCallback) {
        promiseCallback.reject();
      } else {
        return Promise.reject();
      }
    });
  } else {
    return new Promise((resolve, reject) => {
      priorityQueue[id] = {
        priority,
        pdfPage,
        parameters,
        id,
        promiseCallback: {resolve,
        reject}
      };
    });
  }

}
