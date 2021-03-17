// External Dependencies
import { css } from 'glamor';
import { translateX } from 'utils/reader';

// Local Dependencies
import { COLORS } from 'app/constants/AppConstants';
import { PAGE_MARGIN, PDF_PAGE_WIDTH } from 'app/reader/constants';

export const markStyles = css({
  '& mark': {
    background: COLORS.GOLD_LIGHTER,
    '.highlighted': {
      background: COLORS.GREEN_LIGHTER
    }
  }
});

export const pageStyles = ({ width, height, scale, visible }) => ({
  marginBottom: `${PAGE_MARGIN * scale}px`,
  width: `${width}px`,
  height: `${height}px`,
  verticalAlign: 'top',
  display: visible ? '' : 'none'
});

export const pdfStyles = {
  position: 'absolute',
  top: '40%',
  left: '50%',
  width: `${PDF_PAGE_WIDTH}px`,
  transform: 'translate(-50%, -50%)'
};

export const fileContainerStyles = { position: 'relative', width: '100%', height: '100%' };

export const gridStyles = (isVisible) => ({
  visibility: `${isVisible ? 'visible' : 'hidden'}`,
  margin: '0 auto',
  marginBottom: `-${PAGE_MARGIN}px`
});

export const pdfPageStyles = (rotation, height, width) => ({
  transform: `rotate(${rotation}deg) translateX(${translateX(rotation, height, width)}px)`
});
