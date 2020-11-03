import { css } from 'glamor';

export const smallLeftMargin = css({ marginLeft: '1rem' });
export const smallBottomMargin = css({ marginBottom: '1rem' });
export const errorNoTopMargin = css({
  '.usa-input-error': { marginTop: 0 },
});
export const flexContainer = css({
  display: 'flex',
  maxWidth: '75rem',
});
export const flexColumn = css({
  flexDirection: 'row',
  flexWrap: 'wrap',
  width: '50%',
});
