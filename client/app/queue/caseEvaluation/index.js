import { css } from 'glamor';
import { marginBottom, marginTop, paddingLeft } from '../constants';

export const setWidth = (width) =>
  css({
    width,
    maxWidth: width
  });
export const headerStyling = marginBottom(1.5);
export const inlineHeaderStyling = css(headerStyling, { float: 'left' });
export const hrStyling = css(marginTop(2), marginBottom(3));
export const qualityOfWorkAlertStyling = css({ borderLeft: '0.5rem solid #59BDE1' });
export const errorStylingNoTopMargin = css({ '&.usa-input-error': marginTop(0) });
export const subH2Styling = css(paddingLeft(1), { lineHeight: 2 });
export const subH3Styling = css(paddingLeft(1), { lineHeight: 1.75 });
export const fullWidthCheckboxLabels = css(setWidth('100%'));

export const qualityIsDeficient = (val) => ['needs_improvements', 'does_not_meet_expectations'].includes(val);
