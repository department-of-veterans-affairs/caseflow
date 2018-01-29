import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

// poll dependency outage every 2 minutes
export const DEPENDENCY_OUTAGE_POLLING_INTERVAL = 120000;
export const LONGER_THAN_USUAL_TIMEOUT = 10000;
export const CERTIFICATION_DATA_POLLING_INTERVAL = 5000;
export const CERTIFICATION_DATA_OVERALL_TIMEOUT = 180000;

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
    OVERLAP: COLORS.GREY_LIGHT
  },
  CERTIFICATION: {
    ACCENT: '#459FD7',
    OVERLAP: COLORS.GREY_LIGHT
  }
};
