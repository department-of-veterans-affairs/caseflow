/**
 * Helper Method to format the redirect text in the `Back to Queue Link`
 * @param {object} props -- The format components for the redirect link
 */
export const formatRedirectText = ({ queueTaskType, veteranFullName, vbmsId }) => {
  // Set the Base text
  const text = '&lt; Back to ';

  // Set the text to your cases if there is no task type
  if (!queueTaskType) {
    return `${text}your cases`;
  }

  // Set the Text to the Task Type if we do not have the Veterans full name
  if (!veteranFullName) {
    return text + queueTaskType;
  }

  // Default to the Veterans name and VBMS ID
  return `${text}${veteranFullName} (${vbmsId})`;
};
