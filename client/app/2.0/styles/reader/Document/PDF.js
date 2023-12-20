// External Dependencies
import { css } from 'glamor';
import { translateX } from 'utils/reader';

// Local Dependencies
import { COLORS } from 'app/constants/AppConstants';
import { PAGE_MARGIN, PDF_PAGE_WIDTH } from 'store/constants/reader';

const PDF_WRAPPER_SMALL = 1165;

export const markStyles = css({
  '& mark': {
    background: COLORS.GOLD_LIGHTER,
    '.highlighted': {
      background: COLORS.GREEN_LIGHTER
    }
  }
});

export const pageStyles = ({ width, height, scale }) => ({
  marginBottom: `${PAGE_MARGIN * scale}px`,
  width: `${width}px`,
  height: `${height}px`,
  verticalAlign: 'top',
});

export const pdfStyles = {
  position: 'absolute',
  top: '40%',
  left: '50%',
  width: `${PDF_PAGE_WIDTH}px`,
  transform: 'translate(-50%, -50%)'
};

export const fileContainerStyles = { position: 'relative', width: '100%', height: '100%' };

export const gridStyles = () => ({
  visibility: 'visible',
  margin: '0 auto',
  marginBottom: `-${PAGE_MARGIN}px`
});

export const pdfPageStyles = (rotation, height, width) => ({
  transform: `rotate(${rotation}deg) translateX(${translateX(rotation, height, width)}px)`
});

export const toolbarStyles = {
  openSidebarMenu: css({ marginRight: '2%' }),
  toolbar: css({ width: '33%' }),
  toolbarLeft: css({
    '&&': {
      [`@media(max-width:${PDF_WRAPPER_SMALL}px)`]: {
        width: '18%'
      }
    }
  }),
  toolbarCenter: css({
    '&&': {
      [`@media(max-width:${PDF_WRAPPER_SMALL}px)`]: {
        width: '24%'
      }
    }
  }),
  toolbarRight: css({
    textAlign: 'right',
    '&&': {
      [`@media(max-width:${PDF_WRAPPER_SMALL}px)`]: {
        width: '44%',
        '& .cf-pdf-button-text': { display: 'none' }
      }
    }
  }),
  footer: css({
    position: 'absolute',
    bottom: 0,
    display: 'flex',
    alignItems: 'center',
    '&&': {
      [`@media(max-width:${PDF_WRAPPER_SMALL}px)`]: {
        '& .left-button-label': { display: 'none' },
        '& .right-button-label': { display: 'none' }
      }
    }
  })
};

export const pdfButtonStyle = ['cf-pdf-button cf-pdf-spaced-buttons'];

export const pdfWrapper = css({
  width: '72%',
  '@media(max-width: 920px)': {
    width: 'unset',
    right: '250px' },
  '@media(min-width: 1240px )': {
    width: 'unset',
    right: '380px' }
});
