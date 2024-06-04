import { css } from 'glamor';

export const pdfDocumentStyles = css({
  position: 'relative',
  width: '100%',
  height: '100%',
});

export const docViewerStyles = {
  sidebarContainer: css({
    width: '30%',
    top: '0px',
    bottom: '0px',
    right: '0px',
    position: 'absolute',
  }),
  documentContainer: css({
    width: '70%',
  })
};

const docWrapperSmall = 1165;

export const docToolbarStyles = {
  openSidebarMenu: css({ marginRight: '2%' }),
  toolbar: css({ width: '33%' }),
  toolbarLeft: css({
    '&&': { [`@media(max-width:${docWrapperSmall}px)`]: {
      width: '18%' }
    }
  }),
  toolbarCenter: css({
    '&&': { [`@media(max-width:${docWrapperSmall}px)`]: {
      width: '24%' }
    }
  }),
  toolbarRight: css({
    overflow: 'hidden',
    textAlign: 'right',
    '&&': { [`@media(max-width:${docWrapperSmall}px)`]: {
      width: '44%',
      '& .cf-pdf-button-text': { display: 'none' } }
    }
  })
};

export const docFooterStyles = {
  container: css({
    overflow: 'hidden',
    position: 'absolute',
    bottom: 0,
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    '&&': { [`@media(max-width:${docWrapperSmall}px)`]: {
      '& .left-button-label': { display: 'none' },
      '& .right-button-label': { display: 'none' }
    } }
  }),
  pageNumInput: css({
    display: 'inline-block',
  })
};
