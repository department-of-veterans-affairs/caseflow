import { ROTATION_DEGREES } from './readerConstants';

export const getRotationDeg = (rotateDeg) => {
  let updatedRotateDeg;

  switch (rotateDeg) {
    case ROTATION_DEGREES.ZERO:
      updatedRotateDeg = ROTATION_DEGREES.NINETY;
      break;
    case ROTATION_DEGREES.NINETY:
      updatedRotateDeg = ROTATION_DEGREES.ONE_EIGHTY;
      break;
    case ROTATION_DEGREES.ONE_EIGHTY:
      updatedRotateDeg = ROTATION_DEGREES.TWO_SEVENTY;
      break;
    case ROTATION_DEGREES.TWO_SEVENTY:
      updatedRotateDeg = ROTATION_DEGREES.THREE_SIXTY;
      break;
    case ROTATION_DEGREES.THREE_SIXTY:
      updatedRotateDeg = ROTATION_DEGREES.NINETY;
      break;
    default:
      updatedRotateDeg = ROTATION_DEGREES.ZERO;
  }

  return updatedRotateDeg;
};
