import { css } from 'glamor';
import classNames from 'classnames';

export const pdfUiClass = (hideSideBar) => classNames(
  'cf-pdf-container',
  { 'hidden-sidebar': hideSideBar });

export const pdfWrapper = css({
  width: '72%',
  '@media(max-width: 920px)': {
    width: 'unset',
    right: '250px' },
  '@media(min-width: 1240px )': {
    width: 'unset',
    right: '380px' }
});

const pdfWrapperSmall = 1165;

export const pdfToolbarStyles = {
  openSidebarMenu: css({ marginRight: '2%' }),
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
  // TODO replace prototype-footer
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

const sideBarSmall = '250px';
const sideBarLarge = '380px';

export const sidebarWrapper = css({
  width: '28%',
  minWidth: sideBarSmall,
  maxWidth: sideBarLarge,
  '@media(max-width: 920px)': { width: sideBarSmall },
  '@media(min-width: 1240px)': { width: sideBarLarge },
});

export const sidebarClass = (hideSideBar) => classNames('cf-sidebar-wrapper', { 'hidden-sidebar': hideSideBar });

// TODO PdfDocument
export const containerStyle = (isFileVisible) => css({
  width: '100%',
  height: '100%',
  overflow: 'auto',
  paddingTop: '10px',
  paddingLeft: '6px',
  paddingRight: '6px',
  alignContent: 'start',
  justifyContent: 'center',
  gap: '8rem',
  visibility: `${isFileVisible ? 'visible' : 'hidden'}`,
  margin: '0 auto',
  marginBottom: '-25px',
  position: 'absolute',
  top: 0,
  left: 0,
});
