import ReaderBlueCategory from '../svg/reader-blue-category.svg';
import ReaderGreenCategory from '../svg/reader-green-category.svg';
import ReaderPinkCategory from '../svg/reader-pink-category.svg';

// actions
export const TOGGLE_DOCUMENT_CATEGORY = 'TOGGLE_DOCUMENT_CATEGORY';

export const documentCategories = {
  procedural: {
    renderOrder: 0,
    humanName: 'Procedural',
    svg: ReaderBlueCategory
  },
  medical: {
    renderOrder: 1,
    humanName: 'Medical',
    svg: ReaderPinkCategory
  },
  other: {
    renderOrder: 2,
    humanName: 'Other Evidence',
    svg: ReaderGreenCategory
  }
};
