---
name: OdoMate Modern Utility
colors:
  surface: '#faf8ff'
  surface-dim: '#d9d9e5'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3fe'
  surface-container: '#ededf9'
  surface-container-high: '#e7e7f3'
  surface-container-highest: '#e1e2ed'
  on-surface: '#191b23'
  on-surface-variant: '#434655'
  inverse-surface: '#2e3039'
  inverse-on-surface: '#f0f0fb'
  outline: '#737686'
  outline-variant: '#c3c6d7'
  surface-tint: '#0053db'
  primary: '#004ac6'
  on-primary: '#ffffff'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#b4c5ff'
  secondary: '#505f76'
  on-secondary: '#ffffff'
  secondary-container: '#d0e1fb'
  on-secondary-container: '#54647a'
  tertiary: '#00632b'
  on-tertiary: '#ffffff'
  tertiary-container: '#117e3b'
  on-tertiary-container: '#c4ffc9'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#d3e4fe'
  secondary-fixed-dim: '#b7c8e1'
  on-secondary-fixed: '#0b1c30'
  on-secondary-fixed-variant: '#38485d'
  tertiary-fixed: '#95f8a7'
  tertiary-fixed-dim: '#79db8d'
  on-tertiary-fixed: '#00210a'
  on-tertiary-fixed-variant: '#005323'
  background: '#faf8ff'
  on-background: '#191b23'
  surface-variant: '#e1e2ed'
typography:
  headline:
    fontFamily: Poppins
    fontWeight: '600'
  body:
    fontFamily: Poppins
    fontWeight: '400'
  label:
    fontFamily: Poppins
    fontWeight: '500'
  emphasis:
    fontFamily: Poppins
    fontWeight: '700'
  display:
    fontFamily: Poppins
    fontWeight: '800'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
---

Modern offline-first vehicle logbook for everyday riders. Use a clean light utility interface: cool slate background #F8FAFC, white surfaces, thin #E2E8F0 borders, deep navy text #0F172A, muted slate text #64748B, primary blue #2563EB, success green #15803D, warning amber #D97706, danger red #DC2626. Use Poppins throughout: 600 headline, 400 body, 500 label, 700 for numeric metrics and card titles, 800 reserved for the hero odometer and screen wordmarks. All five weights ship as bundled assets under the single `Poppins` family (see `pubspec.yaml`), so a `fontWeight` override selects a real face rather than a synthesised bold. Keep hierarchy strong, cards compact, spacing on a 4px grid, 16px page gutters, 12-16px card radii, subtle outlines instead of heavy shadows. Make mileage and active ride status visually prominent. Use rounded pills only for status labels; buttons and navigation remain structured. Preserve accessible contrast and touch targets.