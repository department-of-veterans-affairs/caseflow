import { css } from 'glamor';

const sideBarSmall = '250px';
const sideBarLarge = '380px';

export const sidebarWrapper = css({
  width: '28%',
  minWidth: sideBarSmall,
  maxWidth: sideBarLarge,
  '@media(max-width: 920px)': { width: sideBarSmall },
  '@media(min-width: 1240px)': { width: sideBarLarge }
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
