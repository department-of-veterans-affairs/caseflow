import { v4 as uuidv4 } from 'uuid';

export default [
  {
    id: '720e728b-3f15-4e44-91c9-abbc62ec8d90',
    eventDate: '07/05/21, 15:00',
    eventUser: 'System',
    readableEventType: 'Claim closed',
    details: {
      decisionDate: '2023-09-12'
    }
  },
  {
    id: '8a805f1c-e35a-4a24-805e-b71505b04592',
    eventDate: '07/05/23, 19:00',
    eventUser: 'System',
    readableEventType: 'Claim created',
    details: {
      decisionDate: '2023-07-05'
    }
  },
  {
    id: 'e38c40e1-398c-4dfe-a9cd-239449c112c9',
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
    id: 'bd1e167e-e047-467b-b2fd-116d062a7e21',
    eventDate: '07/05/23, 15:00',
    eventUser: 'System',
    readableEventType: 'Claim status - In Progress',
    details: {
      decisionDate: '2023-04-12'
    }
  },
  {
    id: 'a70fb69a-7f92-4d02-b49c-ab7fd9510c1f',
    eventDate: '07/05/23, 15:00',
    eventUser: 'System',
    readableEventType: 'Claim status - Incomplete',
    details: {
      decisionDate: ''
    }
  },
  {
    id: '7d872a15-935c-4fa9-b00e-7975b91a2680',
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
    id: 'e1868f25-be4e-49a4-b7a5-debc04685822',
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
    id: 'd9ee8cb9-ca80-4e90-a6ac-219377f97f74',
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
    id: '8f65e8bb-c501-4896-a1a0-fff1a433fb51',
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
    id: 'f1db03e8-156a-419f-9670-ba7554db391a',
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
