import _ from 'lodash';
import { PRINT_WINDOW_TIMEOUT_IN_MS } from '../constants/AppConstants';

export const openPrintDialogue = () => {
  setTimeout(() => window.print(), PRINT_WINDOW_TIMEOUT_IN_MS);
};

export const navigateToPrintPage = (url) => {
  window.open(
    _.isUndefined(url) ? `${window.location.pathname}/print` : url,
    '_blank',
    'noopener noreferrer'
  );
};
