# Media Information Dialog - Design Update

## Overview

The media information dialog has been completely redesigned to be more visually appealing and user-friendly.

## Design Features

### 1. **Modern Dialog Layout**
- Custom dialog with rounded corners (16px radius)
- Max width constraint (400px) for better readability
- Divided into three distinct sections: Header, Content, Actions

### 2. **Header Section**
- Colored background using primary color at 10% opacity
- Large icon (28px) representing media type (photo/video)
- File name prominently displayed with ellipsis for long names
- Media type subtitle for quick identification

### 3. **Content Organization**
Information is grouped into logical sections with icons:

#### File Information Section (📄)
- Extension
- File size
- Capture date with formatted time
- Video duration (if applicable)

#### Orientation Data Section (🔄)
- Device manufacturer and model
- Visual rotation indicators showing actual device angles
- Animated phone icons that rotate to match orientation values
- Color-coded accuracy meter:
  - Green (>80%): Excellent accuracy
  - Orange (50-80%): Good accuracy
  - Red (<50%): Low accuracy

#### Technical Details Section (ℹ️)
- Additional metadata in a clean format
- Automatic formatting of camelCase/snake_case keys

### 4. **Visual Enhancements**

#### Rotation Indicators
- Each orientation value shows a small phone icon rotated to match the degrees
- Icons are contained in subtle colored boxes
- Provides immediate visual understanding of orientation

#### Progress Bar for Accuracy
- Linear progress indicator with color coding
- Percentage displayed alongside
- Smooth visual representation of data quality

#### Consistent Spacing
- 6px vertical padding between rows
- 24px spacing between sections
- 16px padding in content boxes

### 5. **Typography**
- Section headers: 16px bold
- Labels: 14px in muted color
- Values: 14px medium weight
- Clear hierarchy and readability

### 6. **Color Scheme**
- Uses theme colors for consistency
- Primary color for icons and accents
- Muted text for labels
- Card backgrounds for sections
- Subtle borders at 20% opacity

### 7. **Interaction**
- Dismissible by tapping outside
- Scrollable content for long metadata
- Smooth animations and transitions

## Benefits

1. **Better Information Hierarchy**: Related data is grouped together
2. **Visual Clarity**: Icons and colors help quick understanding
3. **Professional Appearance**: Modern design patterns
4. **Accessibility**: Clear contrast and readable text sizes
5. **Responsive**: Works well on different screen sizes

## Usage

The dialog automatically appears when tapping the info button (ℹ️) in the media viewer. It intelligently shows only relevant sections based on available data, keeping the interface clean and focused.