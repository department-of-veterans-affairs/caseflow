import { css } from 'glamor';
import { COLORS } from 'app/constants/AppConstants';

export const commentStyles = {
  width: '100%',
  height: '100%',
  zIndex: 10,
  position: 'relative'
};

export const selectionStyles = css({
  '> div': {
    '::selection': {
      background: COLORS.COLOR_COOL_BLUE_LIGHTER
    },
    '::-moz-selection': {
      background: COLORS.COLOR_COOL_BLUE_LIGHTER
    }
  }
});

export const textLayerStyles = (dimensions, scale) => ({
  width: `${dimensions.width}px`,
  height: `${dimensions.height}px`,
  transform: `scale(${scale})`,
  transformOrigin: 'left top',
  opacity: 1,
});
