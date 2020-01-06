import React from 'react';

import { withKnobs, color } from '@storybook/addon-knobs';

import CaseflowLogo from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/CaseflowLogo';
import { LOGO_COLORS } from '../app/constants/AppConstants';

export default {
  title: 'Commons|Frontend Toolkit/CaseflowLogo',
  component: CaseflowLogo,
  decorators: [withKnobs]
};

export const generic = () => (
  <CaseflowLogo
    accentColor={color('Accent Color', '#5c626b', 'generic')}
    overlapColor={color('Overlap Color', '#4d535b', 'generic')}
  />
);

export const certification = () => (
  <CaseflowLogo
    accentColor={color('Accent Color', LOGO_COLORS.CERTIFICATION.ACCENT, 'certification')}
    overlapColor={color('Overlap Color', LOGO_COLORS.CERTIFICATION.OVERLAP, 'certification')}
  />
);

export const dispatch = () => (
  <CaseflowLogo
    accentColor={color('Accent Color', LOGO_COLORS.DISPATCH.ACCENT, 'dispatch')}
    overlapColor={color('Overlap Color', LOGO_COLORS.DISPATCH.OVERLAP, 'dispatch')}
  />
);

export const eFolder = () => (
  <CaseflowLogo
    accentColor={color('Accent Color', LOGO_COLORS.EFOLDER.ACCENT, 'eFolder')}
    overlapColor={color('Overlap Color', LOGO_COLORS.EFOLDER.OVERLAP, 'eFolder')}
  />
);

export const hearings = () => (
  <CaseflowLogo
    accentColor={color('Accent Color', LOGO_COLORS.HEARINGS.ACCENT, 'hearings')}
    overlapColor={color('Overlap Color', LOGO_COLORS.HEARINGS.OVERLAP, 'hearings')}
  />
);

export const intake = () => (
  <CaseflowLogo
    accentColor={color('Accent Color', LOGO_COLORS.INTAKE.ACCENT, 'intake')}
    overlapColor={color('Overlap Color', LOGO_COLORS.INTAKE.OVERLAP, 'intake')}
  />
);

export const queue = () => (
  <CaseflowLogo
    accentColor={color('Accent Color', LOGO_COLORS.QUEUE.ACCENT, 'queue')}
    overlapColor={color('Overlap Color', LOGO_COLORS.QUEUE.OVERLAP, 'queue')}
  />
);

export const reader = () => (
  <CaseflowLogo
    accentColor={color('Accent Color', LOGO_COLORS.READER.ACCENT, 'reader')}
    overlapColor={color('Overlap Color', LOGO_COLORS.READER.OVERLAP, 'reader')}
  />
);
