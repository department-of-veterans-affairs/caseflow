export const views = {
  review_vacatures: { title: 'Review Vacated Decision Issues' },
  add_decisions: { title: 'Add Decisions' },
  admin_actions: { title: 'Admin Actions' },
  submit: { title: 'Submit Draft Decision for Review' }
};

// This might be more elegantly modeled w/ a finite state machine lib like xstate
export const getSteps = (appeal = {}) => {
  const { caseType = '', vacateType = '' } = appeal;

  switch (vacateType?.toLowerCase()) {
  case 'straight_vacate':
    return ['review_vacatures', 'submit'];
  case 'vacate_and_de_novo':
    return ['review_vacatures', 'admin_actions', 'submit'];
  case 'vacate_and_readjudication':
    return ['review_vacatures', 'add_decisions', 'submit'];
  default:
    return caseType?.toLowerCase() === 'de_novo' ? ['add_decisions', 'submit'] : [];
  }
};

export const getNextStep = (current, steps) => {
  const idx = steps.indexOf(current);

  return idx < steps.length - 1 ? steps[idx + 1] : null;
};

export const getPrevStep = (current, steps) => {
  const idx = steps.indexOf(current);

  return idx > 0 ? steps[idx - 1] : null;
};
