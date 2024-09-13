import { css } from 'glamor';

// from PdfUI.jsx //TODO - rename
// PDF Document Viewer is 800px wide or less.
const pdfWrapperSmall = 1165;

export const pdfToolbarStyles = {
  toolbar: css({ width: '33%' }),
  toolbarLeft: css({
    '&&': { [`@media(max-width:${pdfWrapperSmall}px)`]: {
      width: '18%' }
    }
  }),
  toolbarCenter: css({
    '&&': { [`@media(max-width:${pdfWrapperSmall}px)`]: {
      width: '24%' }
    }
  }),
  toolbarRight: css({
    textAlign: 'right',
    '&&': { [`@media(max-width:${pdfWrapperSmall}px)`]: {
      width: '44%',
      '& .cf-pdf-button-text': { display: 'none' } }
    }
  }),
  footer: css({
    position: 'absolute',
    bottom: 0,
    display: 'flex',
    alignItems: 'center',
    '&&': { [`@media(max-width:${pdfWrapperSmall}px)`]: {
      '& .left-button-label': { display: 'none' },
      '& .right-button-label': { display: 'none' }
    } }
  })
};

export const pdfWrapper = css({
  width: '72%',
  '@media(max-width: 920px)': {
    width: 'unset',
    right: '250px' },
  '@media(min-width: 1240px )': {
    width: 'unset',
    right: '380px' }
});
