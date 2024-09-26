import { clamp, compact, get, isEmpty, sortBy, some } from 'lodash';
import React from 'react';
import { ANNOTATION_ICON_SIDE_LENGTH } from '../reader/constants';
import { update } from '../util/ReducerUtil';

export const categoryFieldNameOfCategoryName = (categoryName) => `category_${categoryName}`;

export const keyOfAnnotation = ({ temporaryId, id }) => temporaryId || id;

export const pageNumberOfPageIndex = (pageIndex) => pageIndex + 1;
export const pageIndexOfPageNumber = (pageNumber) => pageNumber - 1;

/**
 * We do a lot of work with coordinates to render PDFs.
 * It is important to keep the various coordinate systems straight.
 * Here are the systems we use:
 *
 *    Root coordinates: The coordinate system for the entire app.
 *      (0, 0) is the top left hand corner of the entire HTML document that the browser has rendered.
 *
 *    Page coordinates: A coordinate system for a given PDF page.
 *      (0, 0) is the top left hand corner of that PDF page.
 *
 * The relationship between root and page coordinates is defined by where the PDF page is within the whole app,
 * and what the current scale factor is.
 *
 * All coordinates in our codebase should have `page` or `root` in the name, to make it clear which
 * coordinate system they belong to. All converting between coordinate systems should be done with
 * the proper helper functions.
 */
export const pageCoordsOfRootCoords = ({ x, y }, pageBoundingBox, scale) => ({
  x: (x - pageBoundingBox.left) / scale,
  y: (y - pageBoundingBox.top) / scale,
});

export const pageCoordsOfRootCoordsPrototype = ({ x, y }, pageBoundingBox, scale) => ({
  x: (x - pageBoundingBox.left) * scale,
  y: (y - pageBoundingBox.top) * scale,
});

export const rotateCoordinates = ({ x, y }, container, rotation) => {
  let rotatedCoords = null;

  switch (rotation) {
  case 90:
    rotatedCoords = { x: y, y: container.width - x };
    break;
  case 180:
    rotatedCoords = { x: container.width - x, y: container.height - y };
    break;
  case 270:
    rotatedCoords = { x: container.height - y, y: x };
    break;
  default:
    rotatedCoords = { x, y };
    break;
  }

  return rotatedCoords;
};

export const getPageCoordinatesOfMouseEvent = (event, container, scale, rotation) => {
  const constrainedRootCoords = {
    x: clamp(event.pageX, container.left, container.right - ANNOTATION_ICON_SIDE_LENGTH),
    y: clamp(event.pageY, container.top, container.bottom - ANNOTATION_ICON_SIDE_LENGTH),
  };

  return rotateCoordinates(pageCoordsOfRootCoords(constrainedRootCoords, container, scale), container, rotation);
};

export const getPageCoordinatesOfMouseEventPrototype = (event, container, scale, rotation) => {
  const constrainedRootCoords = {
    x: clamp(event.pageX, container.left, container.right - ANNOTATION_ICON_SIDE_LENGTH),
    y: clamp(event.pageY, container.top, container.bottom - ANNOTATION_ICON_SIDE_LENGTH),
  };

  return rotateCoordinates(
    pageCoordsOfRootCoordsPrototype(constrainedRootCoords, container, scale),
    container,
    rotation
  );
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
  update(state, {
    ...immutabilityHelperSpecOfPath(srcPath, '$unset', id),
    ...immutabilityHelperSpecOfPath([...destPath, id], '$set', get(state, [...srcPath, id])),
  });

export const isValidWholeNumber = (number) => {
  return !isNaN(number) && number % 1 === 0;
};

export const sortAnnotations = (annotations) => compact(sortBy(annotations, 'page', 'y'));

export const isUserEditingText = () =>
  some(document.querySelectorAll('input,textarea'), (elem) => document.activeElement === elem);

export const getHearingWorksheetLink = (hearings) => {
  return (
    <span>
      {hearings.map((hearing, key) => {
        return (
          <div>
            <a
              target="_blank"
              href={`/hearings/worksheet/print?keep_open=true&hearing_ids=${hearing.external_id}`}
              rel="noopener noreferrer"
              key={key}
            >
              Hearing Worksheet
            </a>
          </div>
        );
      })}
    </span>
  );
};

export const getClaimTypeDetailInfo = (claim) => {
  let appealTypeInfo = '';
  let appealHasHearing = claim.hearings && claim.hearings.length > 0;

  if (claim.cavc && claim.aod) {
    appealTypeInfo = 'AOD, CAVC';
  } else if (claim.cavc) {
    appealTypeInfo = 'CAVC';
  } else if (claim.aod) {
    appealTypeInfo = 'AOD';
  }

  return (
    <div className="claim-detail-container">
      <span className="claim-detail-type-info">{appealTypeInfo}</span>
      {appealHasHearing && getHearingWorksheetLink(claim.hearings)}
    </div>
  );
};

export const handleErrorWithSafeNavigation = (response) => {
  const isJson = get(response, 'response.type') === 'application/json';

  if (!isJson) {
    return null;
  }
  const jsonResponse = get(response, 'response.body');
  const error = get(jsonResponse, 'errors[0].detail', null);

  return error;
};

export const shouldFetchAppeal = (appeal, vacolsIdFromUrl) =>
  isEmpty(appeal) || (appeal.vacols_id || appeal.external_id) !== vacolsIdFromUrl;
