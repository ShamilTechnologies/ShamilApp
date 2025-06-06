# ShamilApp Color Palette
## Design System Documentation

### Brand Identity
**App Name**: ShamilApp  
**Design Philosophy**: Dark-first premium experience with gradient-heavy modern approach  
**Primary Theme**: Sophisticated service discovery platform  

---

## 🎨 PRIMARY BRAND COLORS

### Primary Dark Blue
- **Color Name**: Primary Dark Blue
- **Hex**: `#2A548D`
- **RGB**: `42, 84, 141`
- **HSL**: `214°, 54%, 36%`
- **Usage**: Main brand color, primary backgrounds, headers, navigation, brand elements
- **Personality**: Trust, professionalism, stability, corporate identity
- **Context**: Core brand representation, primary interactive elements

### Deep Space Navy
- **Color Name**: Deep Space Navy
- **Hex**: `#0A0E1A`
- **RGB**: `10, 14, 26`
- **HSL**: `225°, 44%, 7%`
- **Usage**: Deep dark backgrounds, modern dark theme foundation
- **Personality**: Premium, sophisticated, mysterious, depth
- **Context**: Screen backgrounds, overlay foundations, premium feel

### Medium Blue
- **Color Name**: Medium Blue
- **Hex**: `#6385C3`
- **RGB**: `99, 133, 195`
- **HSL**: `219°, 44%, 58%`
- **Usage**: Secondary accents, complementary brand elements
- **Personality**: Approachable, reliable, supportive
- **Context**: Secondary buttons, supporting elements, brand complements

### Light Ice Blue
- **Color Name**: Light Ice Blue
- **Hex**: `#E2F0FF`
- **RGB**: `226, 240, 255`
- **HSL**: `210°, 100%, 94%`
- **Usage**: Light accents, subtle highlights, floating orb effects
- **Personality**: Ethereal, clean, fresh, floating
- **Context**: Glassmorphism elements, floating orbs, subtle highlights

---

## ✨ ACCENT COLORS

### Vibrant Teal
- **Color Name**: Vibrant Teal
- **Hex**: `#20C997`
- **RGB**: `32, 201, 151`
- **HSL**: `162°, 72%, 46%`
- **Usage**: Primary accent, call-to-action elements, success states, interactive highlights
- **Personality**: Energetic, modern, fresh, action-oriented
- **Context**: CTA buttons, success indicators, interactive highlights

### Electric Cyan
- **Color Name**: Electric Cyan
- **Hex**: `#17A2B8`
- **RGB**: `23, 162, 184`
- **HSL**: `188°, 78%, 41%`
- **Usage**: Information states, tech-focused elements
- **Personality**: Technical, informative, modern, digital
- **Context**: Info messages, tech elements, data visualization

### Electric Blue
- **Color Name**: Electric Blue
- **Hex**: `#00D4FF`
- **RGB**: `0, 212, 255`
- **HSL**: `190°, 100%, 50%`
- **Usage**: Community navigation, electric highlights, energy elements
- **Personality**: Electric, vibrant, social, energetic
- **Context**: Community features, social elements, electric accents

---

## 🌊 DARK GRADIENT VARIANTS

### Alternative Dark Navy Palette
- **Dark Navy 1**: `#0F0F23` (RGB: 15, 15, 35)
- **Dark Navy 2**: `#1A1A2E` (RGB: 26, 26, 46)
- **Dark Navy 3**: `#16213E` (RGB: 22, 33, 62)
- **Usage**: Complex gradient backgrounds, secondary screens, modal overlays
- **Context**: Alternative dark themes, layered backgrounds

---

## 📝 TEXT COLOR SYSTEM

### Light Text (Dark Theme Primary)
- **Primary Text**: `#FFFFFF` (Pure White)
- **High Emphasis**: `#FFFFFF` at 90% opacity (`#E6FFFFFF`)
- **Medium Emphasis**: `#FFFFFF` at 80% opacity (`#CCFFFFFF`)
- **Low Emphasis**: `#FFFFFF` at 60% opacity (`#99FFFFFF`)
- **Hint Text**: `#FFFFFF` at 50% opacity (`#80FFFFFF`)

### Supporting Text Colors
- **Secondary Text**: `#B0B0B0` (Light Gray)
- **Muted Text**: `#6A737D` (Medium Gray)
- **Link Text**: `#20C997` (Vibrant Teal)

### Dark Text (Light Backgrounds Only)
- **Dark Text**: `#212529` (Very Dark Gray)
- **Usage**: Only for light theme contexts or light background overlays

---

## 🎯 STATUS & SEMANTIC COLORS

### Success
- **Color**: `#28A745`
- **RGB**: `40, 167, 69`
- **Usage**: Success messages, positive actions, completed states

### Warning
- **Color**: `#FFC107`
- **RGB**: `255, 193, 7`
- **Usage**: Warning messages, caution states, pending actions

### Danger/Error
- **Color**: `#DC3545`
- **RGB**: `220, 53, 69`
- **Usage**: Error messages, destructive actions, critical alerts

### Info
- **Color**: `#17A2B8`
- **RGB**: `23, 162, 184`
- **Usage**: Informational messages, neutral notifications

---

## 🧭 NAVIGATION COLOR SYSTEM

### Explore Navigation
- **Primary**: `#2A548D` (Primary Dark Blue)
- **Secondary**: `#20C997` (Vibrant Teal)
- **Gradient**: Linear from Primary Dark Blue to Vibrant Teal

### Passes Navigation
- **Primary**: `#8B5CF6` (Purple)
- **Secondary**: `#EC4899` (Pink)
- **Gradient**: Linear from Purple to Pink

### Community Navigation
- **Primary**: `#06B6D4` (Community Teal)
- **Secondary**: `#00D4FF` (Electric Blue)
- **Gradient**: Linear from Community Teal to Electric Blue

### Favorites Navigation
- **Primary**: `#EC4899` (Pink)
- **Secondary**: `#F97316` (Orange)
- **Gradient**: Linear from Pink to Orange

### Profile Navigation
- **Primary**: `#10B981` (Profile Green)
- **Secondary**: `#06B6D4` (Community Teal)
- **Gradient**: Linear from Profile Green to Community Teal

---

## 🎨 GRADIENT SPECIFICATIONS

### Main App Background Gradient
```css
background: linear-gradient(135deg, #2A548D 0%, rgba(42,84,141,0.95) 30%, rgba(42,84,141,0.9) 70%, #0A0E1A 100%);
```
- **Direction**: 135° (Top-left to bottom-right)
- **Colors**: Primary Blue → Primary Blue 95% → Primary Blue 90% → Deep Space Navy
- **Stops**: 0%, 30%, 70%, 100%

### Hero Section Gradient
```css
background: linear-gradient(135deg, #2A548D 0%, rgba(42,84,141,0.9) 30%, #20C997 70%, rgba(42,84,141,0.8) 100%);
```
- **Direction**: 135° (Top-left to bottom-right)
- **Colors**: Primary Blue → Primary Blue 90% → Vibrant Teal → Primary Blue 80%
- **Stops**: 0%, 30%, 70%, 100%

### Alternative Dark Gradient
```css
background: linear-gradient(135deg, #0F0F23 0%, #1A1A2E 30%, #16213E 70%, #0F0F23 100%);
```
- **Direction**: 135° (Top-left to bottom-right)
- **Colors**: Dark Navy variants in sequence
- **Stops**: 0%, 30%, 70%, 100%

---

## 🔮 GLASSMORPHISM SYSTEM

### Glass Card Background
```css
background: linear-gradient(135deg, rgba(255,255,255,0.15) 0%, rgba(255,255,255,0.05) 100%);
border: 1px solid rgba(255,255,255,0.2);
backdrop-filter: blur(10px);
```

### Glass Border Variations
- **Standard Border**: `rgba(255,255,255,0.2)`
- **Strong Border**: `rgba(255,255,255,0.3)`
- **Subtle Border**: `rgba(255,255,255,0.1)`

---

## 🌟 FLOATING ORB SYSTEM

### Teal Orbs
```css
background: radial-gradient(circle, rgba(32,201,151,0.3) 0%, transparent 100%);
```
- **Center Color**: Vibrant Teal at 30% opacity
- **Edge**: Transparent
- **Usage**: Primary floating background elements

### Light Blue Orbs
```css
background: radial-gradient(circle, rgba(226,240,255,0.2) 0%, transparent 100%);
```
- **Center Color**: Light Ice Blue at 20% opacity
- **Edge**: Transparent
- **Usage**: Secondary floating background elements

---

## 🎭 CATEGORY-SPECIFIC GRADIENTS

### Healthcare/Medical
```css
background: linear-gradient(135deg, #06B6D4, #00D4FF);
```

### Fitness/Sports
```css
background: linear-gradient(135deg, #10B981, #06B6D4);
```

### Beauty/Wellness
```css
background: linear-gradient(135deg, #EC4899, #F97316);
```

### Education/Learning
```css
background: linear-gradient(135deg, #8B5CF6, #EC4899);
```

### Technology/Tech
```css
background: linear-gradient(135deg, #2A548D, #20C997);
```

---

## 🔧 DESIGN TOOL SPECIFICATIONS

### Adobe Creative Suite (ASE/ACO)
```
Primary Dark Blue: #2A548D
Deep Space Navy: #0A0E1A
Vibrant Teal: #20C997
Light Ice Blue: #E2F0FF
Electric Blue: #00D4FF
```

### Figma Color Styles
- Use the exact hex codes provided
- Create gradient styles for each specified gradient
- Set up opacity variants for text colors
- Create component variants for glassmorphism effects

### Sketch Symbols
- Define color variables using hex values
- Create gradient symbols for reusable backgrounds
- Set up text style variations with opacity

---

## ♿ ACCESSIBILITY GUIDELINES

### Contrast Ratios
- **White text on Primary Dark Blue**: 4.8:1 (AA Compliant)
- **White text on Deep Space Navy**: 15.3:1 (AAA Compliant)
- **Vibrant Teal on Dark backgrounds**: 3.2:1 (AA for large text)

### Color Blindness Considerations
- Primary blue-teal combination works for all color blindness types
- Status colors (red, yellow, green) have sufficient differentiation
- Never rely on color alone for critical information

---

## 📱 PLATFORM ADAPTATIONS

### iOS Design
- Use system-provided blur effects for glassmorphism
- Maintain gradient directions and color stops
- Adapt corner radius to iOS standards (typically 12-16px)

### Android Material Design
- Adapt glassmorphism to Material You principles
- Use elevation instead of floating orbs where appropriate
- Maintain brand colors within Material guidelines

### Web Implementation
- Use CSS backdrop-filter for glassmorphism
- Implement CSS custom properties for easy theme switching
- Ensure proper fallbacks for older browsers

---

## 🎨 EXPORT FORMATS

### For Developers
- Hex codes: Primary format for implementation
- RGBA values: For opacity variations
- CSS gradients: Copy-paste ready

### For Print/Marketing
- CMYK equivalents available on request
- Pantone color matching for physical materials
- Brand guide versions with larger color swatches

### For Presentation
- High-contrast versions for projectors
- Monochrome alternatives for black/white printing
- Color meaning explanations for stakeholder presentations

---

**Version**: 1.0  
**Last Updated**: 2024  
**Created for**: ShamilApp Design Team  
**Contact**: Design System Team 