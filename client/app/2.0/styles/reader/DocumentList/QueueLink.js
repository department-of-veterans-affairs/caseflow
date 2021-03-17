// External Dependencies
import { css } from 'glamor';

/**
 * Styles for the `Back to Queue Link`
 * @param {boolean} collapse -- Whether the link should be collapsed
 */
export const queueLinkStyles = (collapse) => css({
  marginTop: collapse ? '-1.5rem' : '1.5rem',
  marginBottom: '-1.5rem'
});
