export const prepSaveData = (data) => {
  let saveModel = {};
  let saveModelId = null;

  Object.keys(data).forEach((key) => {
    saveModel[key.split(':')[1]] = data[key];
    if (saveModelId === null) {
      saveModelId = key.split(':')[0];
    }
  });

  return { id: saveModelId,
    model: saveModel };
};
