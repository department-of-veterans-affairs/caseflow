export const views = {
  review_vacatures: { title: 'Review Vacated Decision Issues' },
  add_decisions: { title: 'Add Decisions' },
  submit: { title: 'Submit Draft Decision for Review' }
};

// This might be more elegantly modeled w/ a finite state machine lib like xstate
export const getSteps = ({ caseType, vacateType }) => {
  switch (vacateType?.toLowerCase()) {
  case 'straight_vacate':
  case 'vacate_and_de_novo':
    return ['review_vacatures', 'submit'];
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
