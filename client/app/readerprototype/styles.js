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

export const documentContainer = {
  width: '100%',
  height: '100%',
  overflow: 'auto',
  paddingTop: '10px',
  paddingLeft: '6px',
  paddingRight: '6px',
  alignContent: 'start',
  justifyContent: 'center',
  gap: '8rem',
};
