import { def, get, itBehavesLike, sharedExamplesFor } from 'bdd-lazy-var/getter';
import { centerOfPage, iconKeypressOffset } from '../../../../app/readerprototype/util/coordinates';
import { ROTATION_DEGREES } from '../../../../app/readerprototype/util/readerConstants';

describe('iconKeypressOffset for rotation', () => {
  def('output', () => iconKeypressOffset(get.coords, get.keyDirection, get.rotation));
  def('coords', () => ({ x: 10, y: 20 }));

  sharedExamplesFor('all arrow keys have correct output', () => {
    ['ArrowRight', 'ArrowDown', 'ArrowLeft', 'ArrowUp'].forEach((direction) => {
      describe(direction, () => {
        def('keyDirection', () => direction);

        it(direction, () => {
          expect(get.output).toEqual(get.expectedResult[direction]);
        });
      });
    });

  });

  describe(ROTATION_DEGREES.ZERO, () => {
    def('rotation', () => ROTATION_DEGREES.ZERO);
    def('expectedResult', () => (
      {
        ArrowRight: { x: 15, y: 20 },
        ArrowDown: { x: 10, y: 25 },
        ArrowLeft: { x: 5, y: 20 },
        ArrowUp: { x: 10, y: 15 }
      }
    ));

    itBehavesLike('all arrow keys have correct output');
  });

  describe(ROTATION_DEGREES.NINETY, () => {
    def('rotation', () => ROTATION_DEGREES.NINETY);
    def('expectedResult', () => (
      {
        ArrowRight: { x: 10, y: 15 },
        ArrowDown: { x: 15, y: 20 },
        ArrowLeft: { x: 10, y: 25 },
        ArrowUp: { x: 5, y: 20 }
      }
    ));

    itBehavesLike('all arrow keys have correct output');
  });

  describe(ROTATION_DEGREES.ONE_EIGHTY, () => {
    def('rotation', () => ROTATION_DEGREES.ONE_EIGHTY);
    def('expectedResult', () => (
      {
        ArrowRight: { x: 5, y: 20 },
        ArrowDown: { x: 10, y: 15 },
        ArrowLeft: { x: 15, y: 20 },
        ArrowUp: { x: 10, y: 25 }
      }
    ));

    itBehavesLike('all arrow keys have correct output');
  });

  describe(ROTATION_DEGREES.TWO_SEVENTY, () => {
    def('rotation', () => ROTATION_DEGREES.TWO_SEVENTY);
    def('expectedResult', () => (
      {
        ArrowRight: { x: 10, y: 25 },
        ArrowDown: { x: 5, y: 20 },
        ArrowLeft: { x: 10, y: 15 },
        ArrowUp: { x: 15, y: 20 }
      }
    ));

    itBehavesLike('all arrow keys have correct output');
  });

  describe(ROTATION_DEGREES.THREE_SIXTY, () => {
    def('rotation', () => ROTATION_DEGREES.THREE_SIXTY);
    def('expectedResult', () => (
      {
        ArrowRight: { x: 15, y: 20 },
        ArrowDown: { x: 10, y: 25 },
        ArrowLeft: { x: 5, y: 20 },
        ArrowUp: { x: 10, y: 15 }
      }
    ));

    itBehavesLike('all arrow keys have correct output');
  });
});

describe('centerOfPage', () => {
  def('output', () => centerOfPage(get.boundingRect, get.rotation));
  def('boundingRect', () => ({
    x: 200,
    y: 100,
    width: 80,
    height: 110,
    left: 200,
    right: 280,
    top: 100,
    bottom: 210
  }));
  def('expectedResults', () => ({
    0: { x: 40, y: 55 },
    90: { x: 55, y: 40 },
    180: { x: 40, y: 55 },
    270: { x: 55, y: 40 },
    360: { x: 40, y: 55 }
  }));

  [0, 90, 180, 270, 360].forEach((rotation) => {
    describe(`for ${rotation} degrees rotation`, () => {
      def('rotation', () => rotation);

      it('calculates center of given page', () => {
        expect(get.output).toEqual(get.expectedResults[rotation]);
      });
    });
  });
});
