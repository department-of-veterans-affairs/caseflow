import leverStore from './reducers/Levers/leversReducer';

export const checkIfOtherChangesExist = (currentLever) => {
  const leversWithChangesList = leverStore.getState().levers.filter(
    (lever) => lever.hasValueChanged === true && lever.item !== currentLever.item
  );

  return leversWithChangesList.length > 0;
};
