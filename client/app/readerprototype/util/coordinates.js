import { getPageCoordinatesOfMouseEventPrototype } from '../../reader/utils';
import { OFFSET_INCREMENT, ROTATION_DEGREES } from './readerConstants';

export const iconKeypressOffset = (initialCoords, keyDirection, rotation) => {
  let newX = initialCoords.x;
  let newY = initialCoords.y;

  if (keyDirection === 'ArrowRight') {
    if ([ROTATION_DEGREES.ZERO, ROTATION_DEGREES.THREE_SIXTY].includes(rotation)) {
      newX += OFFSET_INCREMENT;
    } else if (rotation === ROTATION_DEGREES.NINETY) {
      newY -= OFFSET_INCREMENT;
    } else if (rotation === ROTATION_DEGREES.ONE_EIGHTY) {
      newX -= OFFSET_INCREMENT;
    } else {
      newY += OFFSET_INCREMENT;
    }
  }

  if (keyDirection === 'ArrowLeft') {
    if ([ROTATION_DEGREES.ZERO, ROTATION_DEGREES.THREE_SIXTY].includes(rotation)) {
      newX -= OFFSET_INCREMENT;
    } else if (rotation === ROTATION_DEGREES.NINETY) {
      newY += OFFSET_INCREMENT;
    } else if (rotation === ROTATION_DEGREES.ONE_EIGHTY) {
      newX += OFFSET_INCREMENT;
    } else {
      newY -= OFFSET_INCREMENT;
    }
  }

  if (keyDirection === 'ArrowUp') {
    if ([ROTATION_DEGREES.ZERO, ROTATION_DEGREES.THREE_SIXTY].includes(rotation)) {
      newY -= OFFSET_INCREMENT;
    } else if (rotation === ROTATION_DEGREES.NINETY) {
      newX -= OFFSET_INCREMENT;
    } else if (rotation === ROTATION_DEGREES.ONE_EIGHTY) {
      newY += OFFSET_INCREMENT;
    } else {
      newX += OFFSET_INCREMENT;
    }
  }

  if (keyDirection === 'ArrowDown') {
    if ([ROTATION_DEGREES.ZERO, ROTATION_DEGREES.THREE_SIXTY].includes(rotation)) {
      newY += OFFSET_INCREMENT;
    } else if (rotation === ROTATION_DEGREES.NINETY) {
      newX += OFFSET_INCREMENT;
    } else if (rotation === ROTATION_DEGREES.ONE_EIGHTY) {
      newY -= OFFSET_INCREMENT;
    } else {
      newX -= OFFSET_INCREMENT;
    }
  }

  return { x: newX, y: newY };
};

export const centerOfPage = (boundingRect, rotationDegrees) => {
  const { x, y, width, height } = boundingRect;

  let centerX = x + (width / 2);
  let centerY = y + (height / 2);

  const coords = getPageCoordinatesOfMouseEventPrototype(
    { pageX: centerX, pageY: centerY },
    boundingRect,
    1,
    rotationDegrees
  );

  return coords;
};
