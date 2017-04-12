import ReaderBlueCategory from '../svg/reader-blue-category.svg';
import ReaderGreenCategory from '../svg/reader-green-category.svg';
import ReaderPinkCategory from '../svg/reader-pink-category.svg';

// actions
export const TOGGLE_DOCUMENT_CATEGORY = 'TOGGLE_DOCUMENT_CATEGORY';

export const documentCategories = {
  procedural: {
    humanName: 'Procedural',
    svg: ReaderBlueCategory
  },
  medical: {
    humanName: 'Medical',
    svg: ReaderPinkCategory
  },
  other: {
    humanName: 'Other Evidence',
    svg: ReaderGreenCategory
  }
};
