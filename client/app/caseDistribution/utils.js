import leverStore from './reducers/levers/leversReducer';

export const checkIfOtherChangesExist = (currentLever) => {
  // this isn't going to work as is because levers is currently split up into grouping
  /*
    The code will look something like:
    const countChangedItems = (state = initialState) => {
  const { levers } = state;
  // Flatten the array of lever groups into a single array
  const allLevers = Object.values(levers).flat();
  // Use reduce to count the number of items where hasItemChanged is true
  const changedItemsCount = allLevers.reduce((count, lever) => {
    return lever.hasItemChanged ? count + 1 : count;
  }, 0);
  return changedItemsCount;
};

    })
  */
  const leversWithChangesList = leverStore.getState().levers.filter(
    (lever) => lever.hasValueChanged === true && lever.item !== currentLever.item
  );

  return leversWithChangesList.length > 0;
};
