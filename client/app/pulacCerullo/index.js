export const cavcUrl = 'https://www.uscourts.cavc.gov/';
// TODO: determine URL for Chairman's memo
export const chairmanMemoUrl = '';

export const needsPulacCerulloAlert = (tasks) => {
  const taskTypes = tasks.map((t) => t.type);

  return taskTypes.includes('VacateMotionMailTask');
};
