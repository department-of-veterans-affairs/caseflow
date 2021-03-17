// External Dependencies
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
