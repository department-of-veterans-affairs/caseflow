import { css } from 'glamor';

const PDF_WRAPPER_SMALL = 1165;

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

export const pdfButtonStyle = ['cf-pdf-button cf-pdf-spaced-buttons']
;
