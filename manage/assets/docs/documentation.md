# Farm Manager Documentation

Welcome to **Farm Manager** - A comprehensive livestock management platform designed to help farmers digitize and optimize their farming operations.

---

## Table of Contents

- [Farm Manager Documentation](#farm-manager-documentation)
  - [Table of Contents](#table-of-contents)
  - [Getting Started](#getting-started)
    - [Creating an Account](#creating-an-account)
    - [Setting Up Your First Farm](#setting-up-your-first-farm)
    - [Inviting Team Members](#inviting-team-members)
  - [Dashboard Overview](#dashboard-overview)
    - [Quick Stats](#quick-stats)
    - [Navigation Cards](#navigation-cards)
    - [Notification Badge](#notification-badge)
  - [Animal Management](#animal-management)
    - [Adding Animals](#adding-animals)
    - [Animal Profiles](#animal-profiles)
    - [Animal Types \& Breeds](#animal-types--breeds)
    - [Animal Status Types](#animal-status-types)
    - [Tracking Lineage](#tracking-lineage)
  - [Feeding Management](#feeding-management)
    - [Recording Feedings](#recording-feedings)
    - [Feed Types](#feed-types)
    - [Feed Cost Tracking](#feed-cost-tracking)
  - [Weight Tracking](#weight-tracking)
    - [Recording Weights](#recording-weights)
    - [Growth Analytics](#growth-analytics)
  - [Breeding Management](#breeding-management)
    - [Heat Cycle Detection](#heat-cycle-detection)
    - [Breeding Records](#breeding-records)
    - [Pregnancy Tracking](#pregnancy-tracking)
    - [Gestation Periods](#gestation-periods)
    - [Recording Births](#recording-births)
  - [Health Records](#health-records)
    - [Vaccinations](#vaccinations)
    - [Medications](#medications)
    - [Checkups \& Treatments](#checkups--treatments)
    - [Veterinary Information](#veterinary-information)
  - [Financial Management](#financial-management)
    - [Income Tracking](#income-tracking)
    - [Expense Tracking](#expense-tracking)
    - [Budget Planning](#budget-planning)
    - [Payment Integration](#payment-integration)
  - [Reports \& Analytics](#reports--analytics)
    - [Generating Reports](#generating-reports)
    - [Data Export](#data-export)
  - [AI Assistant](#ai-assistant)
    - [Natural Language Commands](#natural-language-commands)
    - [AI-Powered Insights](#ai-powered-insights)
  - [ML Analytics](#ml-analytics)
    - [Weight Predictions](#weight-predictions)
    - [Health Risk Assessment](#health-risk-assessment)
  - [Notifications \& Reminders](#notifications--reminders)
    - [Creating Reminders](#creating-reminders)
    - [Notification Types](#notification-types)
  - [Team Management](#team-management)
    - [User Roles](#user-roles)
    - [Role Permissions Matrix](#role-permissions-matrix)
  - [Settings](#settings)
    - [Profile Settings](#profile-settings)
    - [Farm Settings](#farm-settings)
    - [Theme \& Appearance](#theme--appearance)
  - [FAQ \& Troubleshooting](#faq--troubleshooting)
    - [Frequently Asked Questions](#frequently-asked-questions)
    - [Common Issues](#common-issues)
    - [Getting Support](#getting-support)
  - [Keyboard Shortcuts (Web)](#keyboard-shortcuts-web)
  - [Version History](#version-history)
  - [Credits](#credits)

---

## Getting Started

### Creating an Account

Farm Manager supports multiple authentication methods to get you started quickly:

1. **Email & Password**
   - Click "Create Account" on the landing page
   - Enter your email address and create a secure password
   - Verify your email address through the confirmation link

2. **Google Sign-In**
   - Click "Continue with Google"
   - Select your Google account
   - Grant the necessary permissions

3. **Join with Invite Code**
   - If you've received an invite code from a farm owner, select "I have an invite code"
   - Enter the invite code provided
   - Complete your profile setup

### Setting Up Your First Farm

After creating your account, you'll be prompted to set up your first farm:

1. **Farm Name**: Enter a descriptive name for your farm (e.g., "Green Valley Farm")
2. As the creator, you'll automatically be assigned the **Owner** role with full access

> **Note**: You can manage multiple farms from a single account. Switch between farms using the farm selector in the settings.

### Inviting Team Members

Build your farm team by inviting workers, managers, or veterinarians:

1. Navigate to **Settings** → **Team Management**
2. Click **Generate Invite Code**
3. Fill in the details:
   - **Email**: The email address of the person you're inviting
   - **Role**: Select the appropriate role (Worker, Manager, Vet, or Owner)
   - **Validity**: How long the code should remain active (default: 7 days)
   - **Max Uses**: Number of times the code can be used (default: 1)
4. Share the generated code with your team member

You can also use the **AI Assistant** to generate invite codes:
> "Create an invite code for john@example.com as a worker"

---

## Dashboard Overview

The Dashboard provides a bird's-eye view of your farm operations:

### Quick Stats
- **Total Animals**: Count of all animals in your farm
- **By Status**: Breakdown by health status (Healthy, Sick, Pregnant, etc.)
- **Recent Activity**: Latest feeding, weight, and health records

### Navigation Cards
Quick access to all major modules:
- 🐄 **Animals** - Manage your livestock inventory
- 🍽️ **Feeding** - Track feeding schedules and consumption
- ⚖️ **Weight** - Monitor animal growth
- 💕 **Breeding** - Manage breeding programs
- 🏥 **Health** - Track health records and vaccinations
- 💰 **Financial** - Manage income and expenses
- 📊 **Reports** - Generate detailed reports
- 🤖 **AI Assistant** - Get AI-powered help

### Notification Badge
The notification icon shows the count of:
- Active reminders
- Admin notifications
- System alerts

---

## Animal Management

### Adding Animals

To add a new animal to your farm:

1. Navigate to **Animals** from the dashboard
2. Tap the **+** button
3. Fill in the required information:
   - **Tag ID** (required): Unique identifier (e.g., ear tag number)
   - **Species** (required): Select from Cattle, Goat, Sheep, Pig, Poultry, Rabbit, or Other
   - **Gender** (required): Male or Female
   - **Name** (optional): Give your animal a name
   - **Breed** (optional): Specify the breed
   - **Birth Date** (optional): Date of birth
   - **Purchase Price** (optional): Initial cost
   - **Purchase Date** (optional): When acquired

4. Tap **Save** to add the animal

### Animal Profiles

Each animal has a detailed profile page showing:

**Basic Information**
- Profile photo (tap to change)
- Tag ID and name
- Species, breed, and gender
- Age (automatically calculated)
- Current status

**Records Tabs**
- **Overview**: Summary statistics
- **Feeding**: All feeding records
- **Weight**: Weight history with growth chart
- **Breeding**: Breeding and pregnancy records
- **Health**: Medical history

**Lineage**
- Mother (dam) information
- Father (sire) information
- Offspring list

### Animal Types & Breeds

Farm Manager supports the following animal types:

| Type | Icon | Common Breeds |
|------|------|---------------|
| Cattle | 🐄 | Holstein, Angus, Hereford, Jersey |
| Goat | 🐐 | Boer, Nubian, Alpine, Saanen |
| Sheep | 🐑 | Merino, Suffolk, Dorper, Hampshire |
| Pig | 🐷 | Yorkshire, Duroc, Hampshire, Berkshire |
| Poultry | 🐔 | Rhode Island Red, Leghorn, Broiler |
| Rabbit | 🐰 | New Zealand, Californian, Rex |
| Other | 🐾 | Custom entries |

### Animal Status Types

| Status | Description | Icon Color |
|--------|-------------|------------|
| Healthy | Normal condition | Green |
| Sick | Requires medical attention | Red |
| Pregnant | Confirmed pregnancy | Purple |
| Nursing | Caring for offspring | Blue |
| Sold | Transferred ownership | Orange |
| Deceased | No longer alive | Grey |

### Tracking Lineage

To link parent-child relationships:

1. Open the animal's profile
2. Tap **Edit**
3. In the **Lineage** section:
   - Select **Mother** from your female animals
   - Select **Father** from your male animals
4. Save changes

The app will display:
- Parent information on offspring profiles
- Offspring lists on parent profiles
- Family tree visualization (coming soon)

---

## Feeding Management

### Recording Feedings

Track every feeding to monitor consumption and costs:

1. Navigate to **Feeding** module
2. Tap **+** to add a new feeding record
3. Enter details:
   - **Animal(s)**: Select one or multiple animals
   - **Feed Type**: Choose from available feed types
   - **Quantity**: Amount in kg
   - **Date & Time**: When the feeding occurred
   - **Notes**: Any observations

**Bulk Feeding**: Select multiple animals for group feeding sessions.

### Feed Types

Built-in feed type classifications:

| Type | Description | Typical Use |
|------|-------------|-------------|
| Starter | High protein for young animals | 0-4 weeks |
| Grower | Balanced nutrition for growth | 4-16 weeks |
| Finisher | Energy-rich for market prep | 16+ weeks |
| Maintenance | General adult nutrition | Adults |
| Supplement | Vitamins, minerals, additives | As needed |
| Forage | Grass, hay, silage | Ruminants |
| Custom | User-defined types | Varies |

### Feed Cost Tracking

Track feeding expenses:

1. When adding a feeding record, you can include cost information
2. View aggregated costs in:
   - **Financial** → **Expenses** → **Feed**
   - **Reports** → **Feed Analysis**

---

## Weight Tracking

### Recording Weights

Monitor animal growth with regular weight records:

1. Navigate to **Weight** module
2. Tap **+** to add a weight record
3. Enter:
   - **Animal**: Select the animal
   - **Weight**: Weight in kg
   - **Date**: Measurement date
   - **Method**: Scale type used (optional)
   - **Notes**: Any observations

> **Tip**: The animal's current weight is automatically updated with the most recent recording.

### Growth Analytics

The weight module provides:

**Individual Animal View**
- Weight history chart
- Average daily gain (ADG)
- Growth rate trends
- Target weight comparison

**Herd Overview**
- Average weight by species
- Weight distribution
- Top performers
- Underweight alerts

---

## Breeding Management

### Heat Cycle Detection

Record heat detection for optimal breeding timing:

1. Navigate to **Breeding** module
2. Tap **+** → **Record Heat**
3. Enter:
   - **Female Animal**: Select the animal
   - **Heat Date**: When signs were observed
   - **Signs Observed**: Behavioral indicators
   - **Notes**: Additional observations

The system will:
- Calculate optimal breeding window
- Predict next heat cycle
- Send reminders for upcoming heat detection

### Breeding Records

Document breeding events:

1. Select an animal with "In Heat" status
2. Tap **Record Breeding**
3. Enter:
   - **Breeding Date**: When mating occurred
   - **Sire**: Select the male (or external/AI)
   - **Method**: Natural or Artificial Insemination
   - **Notes**: Breeding observations

### Pregnancy Tracking

After successful breeding:

1. Confirm pregnancy after appropriate waiting period
2. Update status to **Pregnant**
3. The system automatically:
   - Calculates expected delivery date
   - Shows days pregnant counter
   - Schedules delivery reminders

### Gestation Periods

Farm Manager uses species-specific gestation periods:

| Species | Gestation | Delivery Term |
|---------|-----------|---------------|
| Cattle | 283 days (~9 months) | Calving |
| Goat | 150 days (~5 months) | Kidding |
| Sheep | 147 days (~5 months) | Lambing |
| Pig | 114 days (~3.5 months) | Farrowing |
| Rabbit | 31 days (~1 month) | Kindling |
| Poultry | 21 days | Hatching |

### Recording Births

When delivery occurs:

1. Open the breeding record
2. Tap **Record Delivery**
3. Enter:
   - **Delivery Date**: Actual birth date
   - **Litter Size**: Number of offspring
   - **Live Births**: Surviving offspring
   - **Birth Weights**: Individual weights (optional)
   - **Notes**: Delivery observations

The system will:
- Update mother's status to "Nursing"
- Create offspring records (optional)
- Link offspring to parents

---

## Health Records

### Vaccinations

Track all vaccinations for disease prevention:

1. Navigate to **Health** → **Vaccinations**
2. Tap **+** to add a vaccination record
3. Enter:
   - **Animal(s)**: Select one or multiple
   - **Vaccine Name**: Name of vaccine
   - **Manufacturer**: Vaccine producer
   - **Batch Number**: For traceability
   - **Date Administered**: Vaccination date
   - **Next Due Date**: Booster schedule
   - **Administered By**: Vet or staff name
   - **Cost**: Vaccination cost

**Vaccination Reminders**: Automatic reminders are created for next due dates.

### Medications

Record medication treatments:

1. Navigate to **Health** → **Medications**
2. Add a medication record:
   - **Medication Name**: Drug name
   - **Dosage**: Amount per dose
   - **Frequency**: How often (e.g., "twice daily")
   - **Duration**: Treatment length in days
   - **Route**: Oral, injection, topical, etc.
   - **Withdrawal Period**: Days until safe for market

> **Warning**: The system tracks withdrawal periods and alerts you when animals are not safe for sale or consumption.

### Checkups & Treatments

Record general health checkups and treatments:

**Checkups**
- Regular health assessments
- Body condition scores
- Temperature recordings
- General observations

**Treatments**
- Specific condition treatments
- Surgery records
- Recovery tracking
- Follow-up scheduling

### Veterinary Information

Store vet contact information for quick access:

- Veterinarian name
- Contact number
- Clinic address
- Specializations
- Visit history

---

## Financial Management

### Income Tracking

Record all farm income:

**Income Categories**
| Category | Description |
|----------|-------------|
| Animal Sale | Selling livestock |
| Breeding Service | Stud/breeding fees |
| Milk Sale | Dairy products |
| Egg Sale | Poultry products |
| Manure Sale | Organic fertilizer |
| By-Product Sale | Hides, wool, etc. |
| Subsidy/Grant | Government support |
| Other | Miscellaneous income |

**Recording Income**
1. Navigate to **Financial** → **Income**
2. Tap **+** to add:
   - Date and amount
   - Category
   - Linked animal (if applicable)
   - Payment method
   - Reference/receipt number
   - Notes

### Expense Tracking

Track all farm expenses:

**Expense Categories**
| Category | Description |
|----------|-------------|
| Feed | Animal nutrition |
| Veterinary | Vet visits and services |
| Medication | Medical supplies |
| Equipment | Tools and machinery |
| Supplies | Farm supplies |
| Labor | Wages and salaries |
| Utilities | Water, electricity |
| Transport | Vehicle and fuel |
| Maintenance | Repairs and upkeep |
| Insurance | Coverage premiums |
| Taxes | Government levies |
| Other | Miscellaneous expenses |

### Budget Planning

Plan and monitor your farm budget:

1. Navigate to **Financial** → **Budget**
2. Set monthly/annual budgets by category
3. View:
   - Budget vs. actual spending
   - Variance analysis
   - Projected annual totals
   - Cost per animal metrics

### Payment Integration

Farm Manager supports mobile money integration:

**Supported Methods**
- Mobile Money (MTN, Airtel, etc.)
- Bank Transfer
- Cash Recording
- Cheque Tracking

**Wallet Features**
- Check balance
- Send money
- Receive payments
- Transaction history

---

## Reports & Analytics

### Generating Reports

Create comprehensive reports for analysis:

**Available Report Types**

1. **Animal Inventory Report**
   - Total animal count
   - Species distribution
   - Status breakdown
   - Age demographics

2. **Feeding Report**
   - Feed consumption by animal/group
   - Feed cost analysis
   - Consumption trends
   - Feed efficiency metrics

3. **Weight Report**
   - Growth curves
   - Average daily gain
   - Weight distribution
   - Performance rankings

4. **Breeding Report**
   - Conception rates
   - Breeding success metrics
   - Litter size averages
   - Genetic performance

5. **Health Report**
   - Vaccination compliance
   - Common health issues
   - Treatment efficacy
   - Mortality analysis

6. **Financial Report**
   - Profit and loss statement
   - Cash flow analysis
   - Category breakdowns
   - Year-over-year comparison

### Data Export

Export your data in multiple formats:

- **PDF**: Professional reports for printing
- **CSV**: Spreadsheet-compatible data
- **Excel**: Full data with formatting
- **JSON**: Technical integration format

---

## AI Assistant

### Natural Language Commands

Interact with your farm data using natural language:

**Example Commands**

*Animal Queries*
> "Show me all pregnant cattle"
> "How many sick animals do we have?"
> "Find the animal with tag P-123"

*Creating Reminders*
> "Remind me to vaccinate the pigs next week"
> "Set a reminder to check on Maria tomorrow"
> "Create a health reminder for tag C-001"

*Recording Data*
> "Log feeding for goat G-005: 2kg of grower feed"
> "Record weight 45kg for pig P-123"

*Team Management*
> "Create an invite code for john@example.com as a worker"
> "Generate an owner invite for manager@farm.com"

### AI-Powered Insights

The AI assistant can provide:

- **Health Alerts**: "These animals haven't been fed in 48 hours"
- **Breeding Recommendations**: "Optimal breeding window approaching for 3 animals"
- **Financial Insights**: "Feed costs are 20% higher than last month"
- **Performance Analysis**: "Top 5 weight gainers this week"

---

## ML Analytics

### Weight Predictions

Machine learning-powered weight forecasting:

**Features**
- Predict future weight (7, 14, 30 days)
- Confidence intervals
- Growth trajectory analysis
- Optimal market timing

**How It Works**
1. Navigate to **ML** module
2. Select an animal or group
3. Choose prediction horizon
4. View predicted weights and recommendations

### Health Risk Assessment

AI-driven health monitoring:

- Early illness detection
- Risk factor identification
- Preventive action recommendations
- Historical pattern analysis

---

## Notifications & Reminders

### Creating Reminders

Stay on top of farm tasks with reminders:

1. Navigate to **Notifications** → **Reminders**
2. Tap **+** to create:
   - **Title**: Brief reminder description
   - **Description**: Detailed notes
   - **Due Date**: When action is needed
   - **Type**: Health, Feeding, Breeding, General
   - **Priority**: Low, Medium, High
   - **Linked Animal**: Associate with specific animal

### Notification Types

**System Notifications**
- Upcoming vaccinations
- Withdrawal period endings
- Expected delivery dates
- Heat cycle predictions

**Admin Notifications**
- Team member actions
- Low inventory alerts
- Unusual patterns detected
- System updates

**Custom Reminders**
- User-created task reminders
- Follow-up appointments
- Recurring tasks

---

## Team Management

### User Roles

Farm Manager uses role-based access control:

| Role | Description |
|------|-------------|
| **Owner** | Full access to all features and settings. Can manage team members, delete data, and transfer ownership. |
| **Manager** | Can add/edit all records, view reports, and manage daily operations. Cannot delete animals or manage team. |
| **Worker** | Can add daily records (feeding, weight). Cannot edit historical data or access financial information. |
| **Vet** | Specialized access to health and breeding records. Can add medical records and treatments. |

### Role Permissions Matrix

| Feature | Owner | Manager | Worker | Vet |
|---------|-------|---------|--------|-----|
| View Animals | ✅ | ✅ | ✅ | ✅ |
| Add Animals | ✅ | ✅ | ❌ | ❌ |
| Edit Animals | ✅ | ✅ | ❌ | ❌ |
| Delete Animals | ✅ | ❌ | ❌ | ❌ |
| Add Feeding Records | ✅ | ✅ | ✅ | ❌ |
| Add Weight Records | ✅ | ✅ | ✅ | ❌ |
| Add Health Records | ✅ | ✅ | ❌ | ✅ |
| Add Breeding Records | ✅ | ✅ | ❌ | ✅ |
| View Financial | ✅ | ✅ | ❌ | ❌ |
| Manage Financial | ✅ | ✅ | ❌ | ❌ |
| View Reports | ✅ | ✅ | ❌ | ✅ |
| Generate Reports | ✅ | ✅ | ❌ | ❌ |
| Manage Team | ✅ | ❌ | ❌ | ❌ |
| Farm Settings | ✅ | ❌ | ❌ | ❌ |

---

## Settings

### Profile Settings

Manage your personal information:

- **Display Name**: Your name shown in the app
- **Email**: Account email (used for login)
- **Profile Photo**: Your avatar image
- **Password**: Change your password
- **Notifications**: Notification preferences

### Farm Settings

Configure your farm (Owner only):

- **Farm Name**: Update farm name
- **Farm Logo**: Upload farm branding
- **Default Units**: kg/lbs, currency
- **Time Zone**: Local time settings
- **Language**: Interface language

### Theme & Appearance

Customize the app appearance:

- **Theme Mode**: Light, Dark, or System
- **Color Scheme**: Primary color selection
- **Text Size**: Accessibility options
- **Data Display**: Default view preferences

---

## FAQ & Troubleshooting

### Frequently Asked Questions

**Q: How do I switch between multiple farms?**
A: Go to Settings → Farm Selection → Choose the farm you want to manage.

**Q: Can I import existing animal data?**
A: Yes, go to Settings → Import/Export → Import from CSV. Download our template for proper formatting.

**Q: How are weights calculated for young animals?**
A: If birth weight wasn't recorded, the system estimates based on species-standard birth weights.

**Q: What happens when I mark an animal as sold?**
A: The animal remains in your records for historical data but is excluded from active counts and daily operations.

**Q: How do I recover deleted data?**
A: Deleted records are soft-deleted and can be recovered within 30 days. Contact support for assistance.

**Q: Is my data secure?**
A: Yes, all data is encrypted in transit and at rest. We use industry-standard security practices.

### Common Issues

**Issue: App won't sync**
- Check your internet connection
- Force close and reopen the app
- Check for app updates

**Issue: Photos won't upload**
- Ensure you've granted camera/storage permissions
- Check if you have sufficient storage
- Try a smaller image size

**Issue: Notifications not appearing**
- Enable notifications in phone settings
- Check in-app notification preferences
- Ensure background app refresh is enabled

**Issue: Invite code not working**
- Verify the code hasn't expired
- Check if max uses have been reached
- Ensure you're entering the email that received the invite

### Getting Support

If you encounter issues not covered here:

1. **In-App Support**: Settings → Help → Contact Support
2. **Email**: support@farmmanager.app
3. **Documentation**: Access this guide anytime from the landing page

---

## Keyboard Shortcuts (Web)

| Action | Shortcut |
|--------|----------|
| Open Search | `Ctrl/Cmd + K` |
| New Animal | `Ctrl/Cmd + N` |
| Dashboard | `Ctrl/Cmd + D` |
| Settings | `Ctrl/Cmd + ,` |
| Save | `Ctrl/Cmd + S` |
| Cancel/Close | `Esc` |

---

## Version History

| Version | Date | Highlights |
|---------|------|------------|
| 1.0.0 | 2024 | Initial release with core features |
| 1.1.0 | 2024 | Added breeding management |
| 1.2.0 | 2024 | Health records module |
| 1.3.0 | 2025 | AI Assistant integration |
| 1.4.0 | 2025 | ML Analytics (beta) |
| 1.5.0 | 2025 | Payment integration |
| 2.0.0 | 2026 | Multi-farm support, enhanced reporting |

---

## Credits

Farm Manager is built with love for the farming community.

**Technologies Used**
- Flutter & Dart
- Supabase (Backend)
- Google Gemini (AI)
- Riverpod (State Management)

**Open Source**
This project utilizes various open-source packages. See our GitHub repository for full attribution.

---

*Last Updated: January 2026*

*© 2026 Farm Manager. All rights reserved.*
