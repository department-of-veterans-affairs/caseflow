import { getNextAnnotationIconPageCoords } from '../../../app/reader/PdfViewer';
import * as Constants from '../../../app/reader/constants';

describe('PdfViewer', () => {
  describe('getNextAnnotationIconPageCoords', () => {
    const dimensions = {
      test: [
        {
          width: 1000,
          height: 2000
        }
      ]
    };
    const file = 'test';
    const noRotation = 0;

    describe('allowing movement', () => {
      it('up in the middle of the page', () => {
        expect(
          getNextAnnotationIconPageCoords(
            Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.UP,
            {
              pageIndex: 0,
              x: 100,
              y: 200
            },
            dimensions,
            file,
            noRotation
          )
        ).toEqual({
          x: 100,
          y: 195
        });
      });

      it('down in the middle of the page', () => {
        expect(
          getNextAnnotationIconPageCoords(
            Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.DOWN,
            {
              pageIndex: 0,
              x: 100,
              y: 200
            },
            dimensions,
            file,
            noRotation
          )
        ).toEqual({
          x: 100,
          y: 205
        });
      });

      it('left in the middle of the page', () => {
        expect(
          getNextAnnotationIconPageCoords(
            Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.LEFT,
            {
              pageIndex: 0,
              x: 100,
              y: 200
            },
            dimensions,
            file,
            noRotation
          )
        ).toEqual({
          x: 95,
          y: 200
        });
      });

      it('right in the middle of the page', () => {
        expect(
          getNextAnnotationIconPageCoords(
            Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.RIGHT,
            {
              pageIndex: 0,
              x: 100,
              y: 200
            },
            dimensions,
            file,
            noRotation
          )
        ).toEqual({
          x: 105,
          y: 200
        });
      });
    });
    describe('constraining movement', () => {
      it('up at the top of the page', () => {
        expect(
          getNextAnnotationIconPageCoords(
            Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.UP,
            {
              pageIndex: 0,
              x: 100,
              y: 0
            },
            dimensions,
            file,
            noRotation
          )
        ).toEqual({
          x: 100,
          y: 0
        });
      });

      it('left at the left hand side of the page', () => {
        expect(
          getNextAnnotationIconPageCoords(
            Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.LEFT,
            {
              pageIndex: 0,
              x: 0,
              y: 100
            },
            dimensions,
            file,
            noRotation
          )
        ).toEqual({
          x: 0,
          y: 100
        });
      });

      it('right at the right hand side of the page', () => {
        expect(
          getNextAnnotationIconPageCoords(
            Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.RIGHT,
            {
              pageIndex: 0,
              x: 960,
              y: 300
            },
            dimensions,
            file,
            noRotation
          )
        ).toEqual({
          x: 960,
          y: 300
        });
      });

      it('down at the bottom of the page', () => {
        expect(
          getNextAnnotationIconPageCoords(
            Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.DOWN,
            {
              pageIndex: 0,
              x: 0,
              y: 1960
            },
            dimensions,
            file,
            noRotation
          )
        ).toEqual({
          x: 0,
          y: 1960
        });
      });

    });
    describe('when rotated 90 degrees', () => {
      const oneRotation = 90;

      it('up in the middle of the page', () => {
        expect(
          getNextAnnotationIconPageCoords(
            Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.UP,
            {
              pageIndex: 0,
              x: 100,
              y: 200
            },
            dimensions,
            file,
            oneRotation
          )
        ).toEqual({
          x: 95,
          y: 200
        });
      });

      it('down in the middle of the page', () => {
        expect(
          getNextAnnotationIconPageCoords(
            Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.DOWN,
            {
              pageIndex: 0,
              x: 100,
              y: 200
            },
            dimensions,
            file,
            oneRotation
          )
        ).toEqual({
          x: 105,
          y: 200
        });
      });

      it('left in the middle of the page', () => {
        expect(
          getNextAnnotationIconPageCoords(
            Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.LEFT,
            {
              pageIndex: 0,
              x: 100,
              y: 200
            },
            dimensions,
            file,
            oneRotation
          )
        ).toEqual({
          x: 100,
          y: 205
        });
      });

      it('right in the middle of the page', () => {
        expect(
          getNextAnnotationIconPageCoords(
            Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.RIGHT,
            {
              pageIndex: 0,
              x: 100,
              y: 200
            },
            dimensions,
            file,
            oneRotation
          )
        ).toEqual({
          x: 100,
          y: 195
        });
      });
    });
  });
});
