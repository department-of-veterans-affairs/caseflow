// External Dependencies
import { some } from 'lodash';

/**
 * Helper Method to Determine if the User is editing text
 */
export const isUserEditingText = () => some(
  document.querySelectorAll('input,textarea'),
  (elem) => document.activeElement === elem
);
