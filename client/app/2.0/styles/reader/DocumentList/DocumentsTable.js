// External Dependencies
import { css } from 'glamor';

/**
 * Category Label sub-component styles
 */
export const categoryLabelStyles = css({
  display: 'flex',
  alignItems: 'flex-start',
  marginBottom: 0,
  paddingBottom: 0
});

/**
 * Category Name sub-component styles
 */
export const categoryNameStyles = css({
  lineHeight: 1,
  paddingLeft: '7px'
});

/**
 * Document Category Picker Component styles
 */
export const docCategoryPickerStyles = css({
  listStyleType: 'none',
  paddingLeft: 0,
  paddingBottom: 0,
  width: '193px',
  '& li':
    {
      marginBottom: 0,
      '& .cf-form-checkboxes': {
        marginTop: 0,
        marginBottom: 0,
        '& label': {
          marginBottom: 0
        }
      }
    },
  '& li:last-child': {
    div: { marginBottom: 0 },
    '& .cf-form-checkboxes': { marginBottom: 0 }
  }
});

/**
 * Tag List sub-component styles
 */
export const tagListStyles = css({
  paddingBottom: 0,
  margin: 0,
  maxHeight: '345px',
  wordBreak: 'break-word',
  width: '218px',
  overflowY: 'auto',
  listStyleType: 'none',
  paddingLeft: 0
});

/**
 * Tag List Item sub-component styles
 */
export const tagListItemStyles = css({
  '& .cf-form-checkboxes': {
    marginBottom: 0,
    marginTop: 0,
    '& label': {
      marginBottom: 0
    }
  }
});
