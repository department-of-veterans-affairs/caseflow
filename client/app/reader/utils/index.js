/**
 * Helper Method to update the focus of the Documents Table
 * @param {element} lastReadRef -- React ref to the current Last Read Indicator
 * @param {element} tbodyRef -- React ref to the current Table Body
 */
export const focusElement = (lastReadRef, tbodyRef) => {
  // Set the Initial Scroll position
  let scrollTop = tbodyRef.scrollTop;

  // Focus the Last Read Indicator if present
  if (lastReadRef) {
    // Get the Last Read Indicator Boundary
    const lastReadContainer = lastReadRef.getBoundingClientRect();

    // Get the Table Body Boundary
    const tbodyContainer = tbodyRef.getBoundingClientRect();

    // Check if the Last Read Indicator is in view based on whether it is in the table body boundary
    if (tbodyContainer.top >= lastReadContainer.top && lastReadContainer.bottom >= tbodyContainer.bottom) {
      // Find the row to focus
      const rowWithLastRead = find(tbodyRef.children, (tr) => tr.querySelector(`#${lastReadRef.id}`));

      // Update the scroll position to focus the Last Read Row
      scrollTop += rowWithLastRead.getBoundingClientRect().top - tbodyContainer.top;
    }
  }

  // Return the Scroll Position to update the table
  return scrollTop;
};

export * from './format';
export * from './search';
export * from './pdf';
export * from './document';
export * from './comments';
export * from './coordinates';
export * from './keyboard';
export * from './user';
export * from './appeal';
