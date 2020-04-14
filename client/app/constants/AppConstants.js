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
