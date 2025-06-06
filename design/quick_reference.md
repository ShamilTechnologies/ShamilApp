# ShamilApp Color Quick Reference

## 🎯 Most Used Colors

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| **Primary Dark Blue** | `#2A548D` | Main brand, headers, primary buttons |
| **Deep Space Navy** | `#0A0E1A` | Dark backgrounds, screen foundations |
| **Vibrant Teal** | `#20C997` | Call-to-action, highlights, success |
| **Light Ice Blue** | `#E2F0FF` | Glassmorphism, floating orbs, accents |
| **White Text** | `#FFFFFF` | All primary text on dark backgrounds |

## 🌈 Ready-to-Use Gradients

### Main App Background
```css
background: linear-gradient(135deg, #2A548D 0%, rgba(42,84,141,0.95) 30%, rgba(42,84,141,0.9) 70%, #0A0E1A 100%);
```

### Hero Section
```css
background: linear-gradient(135deg, #2A548D 0%, rgba(42,84,141,0.9) 30%, #20C997 70%, rgba(42,84,141,0.8) 100%);
```

### Glassmorphism Card
```css
background: linear-gradient(135deg, rgba(255,255,255,0.15) 0%, rgba(255,255,255,0.05) 100%);
border: 1px solid rgba(255,255,255,0.2);
backdrop-filter: blur(10px);
```

## 🧭 Navigation Colors

| Tab | Primary | Secondary | Gradient |
|-----|---------|-----------|----------|
| **Explore** | `#2A548D` | `#20C997` | Blue → Teal |
| **Passes** | `#8B5CF6` | `#EC4899` | Purple → Pink |
| **Community** | `#06B6D4` | `#00D4FF` | Teal → Electric Blue |
| **Favorites** | `#EC4899` | `#F97316` | Pink → Orange |
| **Profile** | `#10B981` | `#06B6D4` | Green → Teal |

## 📝 Text Opacity Scale

| Text Type | Color | Usage |
|-----------|-------|-------|
| **Primary** | `#FFFFFF` | Headlines, important text |
| **High Emphasis** | `#FFFFFF` @ 90% | Body text, descriptions |
| **Medium Emphasis** | `#FFFFFF` @ 80% | Supporting text |
| **Low Emphasis** | `#FFFFFF` @ 60% | Captions, metadata |
| **Hint** | `#FFFFFF` @ 50% | Placeholders, disabled text |

## 🎯 Status Colors

| Status | Color | Hex |
|--------|-------|-----|
| **Success** | Green | `#28A745` |
| **Warning** | Amber | `#FFC107` |
| **Danger** | Red | `#DC3545` |
| **Info** | Cyan | `#17A2B8` |

## 🔮 Glassmorphism Quick Setup

```css
/* Standard Glass Card */
.glass-card {
  background: linear-gradient(135deg, rgba(255,255,255,0.15), rgba(255,255,255,0.05));
  border: 1px solid rgba(255,255,255,0.2);
  border-radius: 16px;
  backdrop-filter: blur(10px);
  box-shadow: 0 8px 20px rgba(0,0,0,0.1);
}

/* Strong Glass Border */
.glass-strong {
  border: 1px solid rgba(255,255,255,0.3);
}

/* Subtle Glass Border */
.glass-subtle {
  border: 1px solid rgba(255,255,255,0.1);
}
```

## 🌟 Floating Orbs

```css
/* Teal Orb */
.orb-teal {
  background: radial-gradient(circle, rgba(32,201,151,0.3), transparent);
}

/* Light Blue Orb */
.orb-light {
  background: radial-gradient(circle, rgba(226,240,255,0.2), transparent);
}
```

## 🎨 Category Colors

| Category | Gradient |
|----------|----------|
| **Healthcare** | `#06B6D4` → `#00D4FF` |
| **Fitness** | `#10B981` → `#06B6D4` |
| **Beauty** | `#EC4899` → `#F97316` |
| **Education** | `#8B5CF6` → `#EC4899` |
| **Technology** | `#2A548D` → `#20C997` |

---

## 💡 Pro Tips for Designers

1. **Always use white text** on dark backgrounds
2. **Use glassmorphism** for floating UI elements
3. **Apply gradients** to create depth and premium feel
4. **Maintain 135° gradient direction** for consistency
5. **Use teal accent** for all call-to-action elements
6. **Layer floating orbs** behind content for ambiance
7. **Follow opacity scale** for text hierarchy

---

**Quick access**: Save this as a bookmark for instant color reference! 