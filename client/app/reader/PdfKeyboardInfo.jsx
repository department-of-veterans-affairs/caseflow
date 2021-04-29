import React from 'react';
import { ArrowUp, ArrowDown, ArrowLeft, ArrowRight } from '../components/RenderFunctions';

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
    shortcut: <span><code>alt</code> + <code>enter</code></span> },
  { commentInstruction: 'Save a comment',
    shortcut: <span><code>alt</code> + <code>enter</code></span> }
];

export const commentColumns = [{ header: 'Add/ edit comment',
  valueName: 'commentInstruction',
  align: 'left' },
{ header: 'Shortcut',
  valueName: 'shortcut',
  align: 'left' }];

export const searchColumns = [{ header: 'Search within document',
  valueName: 'searchInstruction',
  align: 'left'
}, { header: 'Shortcut',
  valueName: 'shortcut',
  align: 'left' }];

let metaKey = 'ctrl';

if (navigator.appVersion && navigator.appVersion.includes('Mac')) {
  metaKey = 'cmd';
}

export const searchInstructions = [
  { searchInstruction: 'Open search box',
    shortcut: <span><code>{metaKey}</code> + <code>f</code></span> },
  { searchInstruction: 'Navigate search results',
    shortcut: <span><code>{metaKey}</code> + <code>g</code></span> }
];

export const documentsInstructions = [
  { documentsInstruction: 'Scroll page up',
    shortcut: <span><code>shift</code> + <code>space</code></span> },
  { documentsInstruction: 'Scroll page down',
    shortcut: <span><code>space</code></span> },
  { documentsInstruction: 'View next document',
    shortcut: <span><ArrowRight /></span> },
  { documentsInstruction: 'View previous document',
    shortcut: <span><ArrowLeft /></span> },
  { documentsInstruction: 'Open/ Hide menu',
    shortcut: <span><code>alt</code> + <code>m</code></span> },
  { documentsInstruction: 'Back to document list',
    shortcut: <span><code>alt</code> + <code>backspace</code></span> }
];

export const documentsColumns = [{ header: 'Navigate reader',
  valueName: 'documentsInstruction',
  align: 'left' },
{ header: 'Shortcut',
  valueName: 'shortcut',
  align: 'left' }];

export const categoryColumns = [{ header: 'Add/Remove categories',
  valueName: 'categoryInstruction',
  align: 'left' },
{ header: 'Shortcut',
  valueName: 'shortcut',
  align: 'left' }];

export const categoryInstructions = [
  { categoryInstruction: 'Add/Remove Medical',
    shortcut: <span><code>alt</code> + <code>shift</code> + <code>m</code></span> },
  { categoryInstruction: 'Add/Remove Procedural',
    shortcut: <span><code><code>alt</code> + <code>shift</code></code> + <code>p</code></span> },
  { categoryInstruction: 'Add/Remove Other Evidence',
    shortcut: <span><code><code>alt</code> + <code>shift</code></code> + <code>o</code></span> },
];
