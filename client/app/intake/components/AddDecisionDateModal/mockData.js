const closeHandler = () => {
  // eslint-disable-next-line no-console
  console.log('Close');
};

const currentIssue = {
  id: '4310',
  benefitType: 'vha',
  description: 'Beneficiary Travel - Issue Description',
  decisionDate: null,
  decisionReviewTitle: 'Higher-Level Review',
  contentionText: 'Beneficiary Travel - Issue Description',
  category: 'Beneficiary Travel',
};

const index = 0;

export default {
  closeHandler,
  currentIssue,
  index
};
