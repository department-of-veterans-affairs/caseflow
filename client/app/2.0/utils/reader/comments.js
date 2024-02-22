
/**
 * Method to scroll the DOM to focus the comment details
 * @param {Object} comment -- The comment to focus
 */
export const focusComment = (comment) => {
  // Set the comment component
  const commentComponent = document.getElementById(`comment-${comment.id}`);
  const commentIcon = document.getElementById(`commentIcon-container-${comment.id}`);

  // Focus the comment if found
  if (commentComponent) {
    // Scroll the comment into view
    commentComponent.scrollIntoView();
  }

  if (commentIcon) {
    // Scroll the comment into view
    commentIcon.scrollIntoView();
  }
};
