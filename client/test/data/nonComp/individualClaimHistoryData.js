import { v4 as uuidv4 } from 'uuid';

export default [
  {
    id: uuidv4(),
    eventDate: '07/05/21, 15:00',
    eventUser: 'System',
    readableEventType: 'Claim closed',
    details: {
      decisionDate: '2023-09-12'
    }
  },
  {
    id: uuidv4(),
    eventDate: '07/05/23, 19:00',
    eventUser: 'System',
    readableEventType: 'Claim created',
    details: {
      decisionDate: '2023-07-05'
    }
  },
  {
    id: uuidv4(),
    eventDate: '07/05/24, 15:00',
    eventUser: 'J. Dudifer',
    readableEventType: 'Completed disposition',
    details: {
      benefitType: 'vha',
      issueType: 'Beneficiary Travel',
      issueDescription: 'Any notes will display here',
      decisionDate: '2023-05-31',
      disposition: 'Granted',
      decisionDescription: 'Any notes from decision will display here'
    }
  },
  {
    id: uuidv4(),
    eventDate: '07/05/23, 15:00',
    eventUser: 'System',
    readableEventType: 'Claim status - In progress',
    details: {
      decisionDate: '2023-04-12'
    }
  },
  {
    id: uuidv4(),
    eventDate: '07/05/23, 15:00',
    eventUser: 'System',
    readableEventType: 'Claim status - Incomplete',
    details: {
      decisionDate: ''
    }
  },
  {
    id: uuidv4(),
    eventDate: '07/05/23, 15:00',
    eventUser: 'System',
    readableEventType: 'Added issue',
    details: {
      benefitType: 'vha',
      issueType: 'Beneficiary Travel',
      issueDescription: 'Any notes will display here',
      decisionDate: '2023-05-31',
      disposition: 'Granted',
      decisionDescription: 'Any notes from decision will display here'
    }
  },
  {
    id: uuidv4(),
    eventDate: '07/05/23, 15:00',
    eventUser: 'System',
    readableEventType: 'Added decision date',
    details: {
      benefitType: 'vha',
      issueType: 'Beneficiary Travel',
      issueDescription: 'Any notes will display here',
      decisionDate: '2023-05-31',
      disposition: 'Granted',
      decisionDescription: 'Any notes from decision will display here'
    }
  },
  {
    id: uuidv4(),
    eventDate: '07/05/23, 15:00',
    eventUser: 'System',
    readableEventType: 'Added issue - No decision date',
    details: {
      benefitType: 'vha',
      issueType: 'Beneficiary Travel',
      issueDescription: 'Any notes will display here',
      decisionDate: '',
      disposition: 'Granted',
      decisionDescription: 'Any notes from decision will display here'
    }
  },
  {
    id: uuidv4(),
    eventDate: '07/05/23, 15:00',
    eventUser: 'System',
    readableEventType: 'Withdrew issue',
    details: {
      benefitType: 'vha',
      issueType: 'Beneficiary Travel',
      issueDescription: 'Any notes will display here',
      decisionDate: '2023-06-23',
      withdrawalRequestDate: '07/05/23',
    }
  },
  {
    id: uuidv4(),
    eventDate: '07/05/23, 15:15',
    eventUser: 'System',
    readableEventType: 'Removed issue',
    details: {
      benefitType: 'vha',
      issueType: 'Beneficiary Travel',
      issueDescription: 'Any notes will display here',
      decisionDate: '2023-06-23',
      withdrawalRequestDate: '07/05/23',
    }
  },
];
