import { expect } from 'chai';
import { getNextAnnotationIconPageCoords } from '../../../app/reader/PdfViewer';
import * as Constants from '../../../app/reader/constants';

describe('PdfViewer', () => {
  describe('getNextAnnotationIconPageCoords', () => {
    it('allows movement in the middle of the page', () => {
      expect(
        getNextAnnotationIconPageCoords(
          Constants.MOVE_ANNOTATION_ICON_DIRECTIONS.UP,
          {
            pageIndex: 1,
            x: 100,
            y: 200
          },
          {
            1: {
              width: 1000,
              height: 2000
            }
          }
        )
      ).to.deep.equal({
        x: 100,
        y: 195
      });
    });
  });
});
