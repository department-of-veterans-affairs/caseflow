import React from 'react';
import { ArrowUp, ArrowDown, ArrowLeft, ArrowRight } from './RenderFunctions';

export const scrollInstructions = [
  { scrollInstruction: 'Page up',
    shortcut: <span><code>shift</code> + <code>space</code></span> },
  { scrollInstruction: 'Page down',
    shortcut: <span><code>space</code></span> }
];

export const scrollColumns = [{ header: 'Scroll',
  valueName: 'scrollInstruction',
  align: 'left' },
{ header: 'Shortcut',
  valueName: 'shortcut',
  align: 'left' }];

export const commentInstructions = [
  { commentInstruction: 'Add comment mode',
    shortcut: <span><code>alt</code> + <code>c</code></span> },
  { commentInstruction: 'Move comment up',
    shortcut: <span><ArrowUp /></span> },
  { commentInstruction: 'Move comment down',
    shortcut: <span><ArrowDown /></span> },
  { commentInstruction: 'Move comment left',
    shortcut: <span><ArrowLeft /></span> },
  { commentInstruction: 'Move comment right',
    shortcut: <span><ArrowRight /></span> },
  { commentInstruction: 'Place a comment',
    shortcut: <span><code>alt</code> + <code>enter</code></span> }
];

export const commentColumns = [{ header: 'Add/ edit comment',
  valueName: 'commentInstruction',
  align: 'left' },
{ header: 'Shortcut',
  valueName: 'shortcut',
  align: 'left' }];

export const documentsInstructions = [
  { documentsInstruction: 'Next document',
    shortcut: <span><ArrowRight /></span> },
  { documentsInstruction: 'Previous document',
    shortcut: <span><ArrowLeft /></span> }
];

export const documentsColumns = [{ header: 'View documents',
  valueName: 'documentsInstruction',
  align: 'left' },
{ header: 'Shortcut',
  valueName: 'shortcut',
  align: 'left' }];
