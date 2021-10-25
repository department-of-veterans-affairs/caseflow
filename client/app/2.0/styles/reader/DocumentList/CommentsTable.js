import classNames from 'classnames';

/**
 * Class Styles for the comment component
 * @param {boolean} selected -- Whether the comments container is selected
 * @param {boolean} horizontalLayout -- Whether to use a horizontal layout
 */
export const commentsClass = (selected, horizontalLayout) => classNames('comment-container', {
  'comment-container-selected': selected,
  'comment-horizontal-container': horizontalLayout
});
