import { PRINT_WINDOW_TIMEOUT_IN_MS } from '../constants/AppConstants';

export const openPrintDialogue = () => {
  setTimeout(() => window.print(), PRINT_WINDOW_TIMEOUT_IN_MS);
};

export const navigateToPrintPage = () => {
  // A route for the current path + /print must exist for this to
  // work.
  window.open(`${window.location.pathname}/print`, '_blank', 'noopener noreferrer');
};
