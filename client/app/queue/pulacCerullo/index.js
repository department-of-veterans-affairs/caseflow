export const cavcUrl = 'https://www.uscourts.cavc.gov/';
export const chairmanMemoUrl = '/assets/chairman_memorandum_01-10-18.pdf';

export const needsPulacCerulloAlert = (appeal, tasks) => {
  if (appeal?.caseType?.toLowerCase() === 'vacate') {
    return true;
  }

  const taskTypes = tasks.map((task) => task.type);

  return taskTypes.includes('VacateMotionMailTask');
};
