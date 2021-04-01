import { COLORS as COMMON_COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

// poll dependency outage every 2 minutes
export const DEPENDENCY_OUTAGE_POLLING_INTERVAL = 120000;
export const LONGER_THAN_USUAL_TIMEOUT = 10000;
export const CERTIFICATION_DATA_POLLING_INTERVAL = 5000;
export const CERTIFICATION_DATA_OVERALL_TIMEOUT = 180000;
export const PRINT_WINDOW_TIMEOUT_IN_MS = 300;

export const COLORS = {
  ...COMMON_COLORS,
  GREEN: '#2e8540',
  GREY: '#5b616b',
  GOLD_LIGHTEST: '#FFF1D2',
  GOLD_LIGHTER: '#FAD980',
  GOLD_LIGHT: '#F9C642',
  GREEN_LIGHTER: '#94BFA2',
  GREY_BACKGROUND: '#f9f9f9',
  COLOR_COOL_BLUE_LIGHTER: '#8ba6ca',
  PRIMARY: '#0071bc',
  BASE: '#212121',
  RED: '#E31C3D',
  RED_DARK: '#cd2026'
};

export const LOGO_COLORS = {
  READER: {
    ACCENT: '#417505',
    OVERLAP: '#2D5104'
  },
  INTAKE: {
    ACCENT: '#FFCC4E',
    OVERLAP: '#CA9E00'
  },
  DISPATCH: {
    ACCENT: '#844e9f',
    OVERLAP: '#7a4b91'
  },
  HEARINGS: {
    ACCENT: '#56b605',
    OVERLAP: COMMON_COLORS.GREY_LIGHT
  },
  CERTIFICATION: {
    ACCENT: '#459FD7',
    OVERLAP: COMMON_COLORS.GREY_LIGHT
  },
  QUEUE: {
    ACCENT: '#11598D',
    OVERLAP: '#0E456C'
  },
  EFOLDER: {
    ACCENT: '#F0835e',
    OVERLAP: COMMON_COLORS.GREY_LIGHT
  }
};

export const COMMON_TIMEZONES = [
  'America/Los_Angeles',
  'America/Denver',
  'America/Chicago',
  'America/New_York'
];

// NOTE: This information was determined by googling `what timezone is X` for each of the keys
export const REGIONAL_OFFICE_ZONE_ALIASES = {
  'America/Anchorage': 'America/Juneau',
  'America/Boise': 'America/Denver',
  'America/Kentucky/Louisville': 'America/New_York'
};

// https://faq.usps.com/s/article/What-are-the-USPS-abbreviations-for-U-S-states-and-territories
export const STATES = [
  { label: 'AL', value: 'Alabama' },
  { label: 'AK', value: 'Alaska' },
  { label: 'AS', value: 'American Samoa' },
  { label: 'AZ', value: 'Arizona' },
  { label: 'AR', value: 'Arkansas' },
  { label: 'CA', value: 'California' },
  { label: 'CO', value: 'Colorado' },
  { label: 'CT', value: 'Connecticut' },
  { label: 'DE', value: 'Delaware' },
  { label: 'DC', value: 'District of Columbia' },
  { label: 'FM', value: 'Federated States of Micronesia' },
  { label: 'FL', value: 'Florida' },
  { label: 'GA', value: 'Georgia' },
  { label: 'GU', value: 'Guam' },
  { label: 'HI', value: 'Hawaii' },
  { label: 'ID', value: 'Idaho' },
  { label: 'IL', value: 'Illinois' },
  { label: 'IN', value: 'Indiana' },
  { label: 'IA', value: 'Iowa' },
  { label: 'KS', value: 'Kansas' },
  { label: 'KY', value: 'Kentucky' },
  { label: 'LA', value: 'Louisiana' },
  { label: 'ME', value: 'Maine' },
  { label: 'MH', value: 'Marshall Islands' },
  { label: 'MD', value: 'Maryland' },
  { label: 'MA', value: 'Massachusetts' },
  { label: 'MI', value: 'Michigan' },
  { label: 'MN', value: 'Minnesota' },
  { label: 'MS', value: 'Mississippi' },
  { label: 'MO', value: 'Missouri' },
  { label: 'MT', value: 'Montana' },
  { label: 'NE', value: 'Nebraska' },
  { label: 'NV', value: 'Nevada' },
  { label: 'NH', value: 'New Hampshire' },
  { label: 'NJ', value: 'New Jersey' },
  { label: 'NM', value: 'New Mexico' },
  { label: 'NY', value: 'New York' },
  { label: 'NC', value: 'North Carolina' },
  { label: 'ND', value: 'North Dakota' },
  { label: 'MP', value: 'Northern Mariana Islands' },
  { label: 'OH', value: 'Ohio' },
  { label: 'OK', value: 'Oklahoma' },
  { label: 'OR', value: 'Oregon' },
  { label: 'PW', value: 'Palau' },
  { label: 'PA', value: 'Pennsylvania' },
  { label: 'PR', value: 'Puerto Rico' },
  { label: 'RI', value: 'Rhode Island' },
  { label: 'SC', value: 'South Carolina' },
  { label: 'SD', value: 'South Dakota' },
  { label: 'TN', value: 'Tennessee' },
  { label: 'TX', value: 'Texas' },
  { label: 'UT', value: 'Utah' },
  { label: 'VT', value: 'Vermont' },
  { label: 'VA', value: 'Virginia' },
  { label: 'VI', value: 'Virgin Islands' },
  { label: 'WA', value: 'Washington' },
  { label: 'WV', value: 'West Virginia' },
  { label: 'WI', value: 'Wisconsin' },
  { label: 'WY', value: 'Wyoming' }
];
