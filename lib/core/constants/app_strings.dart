class DuukaStrings {
  DuukaStrings._();

  // App
  static const String appName = 'Duuka';
  static const String appTagline = 'Manage your shop smarter';

  // Auth
  static const String welcomeBack = 'Welcome Back';
  static const String signInToContinue = 'Sign in to continue';
  static const String phoneNumber = 'Phone Number';
  static const String continueText = 'Continue';
  static const String orContinueWith = 'or continue with';
  static const String signInWithGoogle = 'Sign in with Google';
  static const String verifyYourNumber = 'Verify Your Number';
  static const String weSentCode = 'We sent a 6-digit code to';
  static const String didntReceiveCode = "Didn't receive code?";
  static const String resend = 'Resend';
  static const String verify = 'Verify';

  // Onboarding
  static const String welcomeToDuuka = 'Welcome to Duuka!';
  static const String letsSetupBusiness = "Let's set up your business profile.\nThis will only take 2 minutes.";
  static const String whatTypeOfBusiness = 'What type of business do you run?';
  static const String thisHelpsCustomize = 'This helps us customize your experience';
  static const String tellUsAboutBusiness = 'Tell us about your business';
  static const String infoAppearsOnReceipts = 'This information appears on your receipts';
  static const String howBigIsBusiness = 'How big is your business?';
  static const String helpsRecommendPlan = 'This helps us recommend the right plan for you';
  static const String whereIsBusiness = 'Where is your business?';
  static const String helpsWithLocation = 'This helps with location-based features';
  static const String letsGetStarted = "Let's Get Started";
  static const String skipForNow = 'Skip for now';
  static const String completeSetup = 'Complete Setup';
  static const String youreAllSet = "You're All Set! 🎉";
  static const String businessReadyToGo = 'is ready to go.\nLet\'s start managing your inventory!';
  static const String goToDashboard = 'Go to Dashboard';
  static const String addFirstProduct = 'Add First Product';

  // Business Types (with emojis)
  static const Map<String, String> businessTypes = {
    'retail': '🛒 Retail Shop',
    'pharmacy': '💊 Pharmacy',
    'hardware': '🔧 Hardware',
    'agroInput': '🌾 Agro-Input',
    'restaurant': '🍽️ Restaurant',
    'clothing': '👗 Clothing',
    'cosmetics': '💄 Cosmetics',
    'other': '📦 Other',
  };

  // Business Type Emojis only
  static const Map<String, String> businessTypeEmojis = {
    'retail': '🛒',
    'pharmacy': '💊',
    'hardware': '🔧',
    'agroInput': '🌾',
    'restaurant': '🍽️',
    'clothing': '👗',
    'cosmetics': '💄',
    'other': '📦',
  };

  // Business Sizes
  static const String justStarting = 'Just Starting';
  static const String justStartingDesc = 'Less than 50 items, 1 person';
  static const String smallShop = 'Small Shop';
  static const String smallShopDesc = '50-200 items, 1-2 employees';
  static const String growingBusiness = 'Growing Business';
  static const String growingBusinessDesc = '200-500 items, 3-5 employees';
  static const String established = 'Established';
  static const String establishedDesc = '500+ items, multiple branches';

  // Pricing
  static const String free = 'Free';
  static const String starterPrice = 'UGX 10,000/mo';
  static const String businessPrice = 'UGX 25,000/mo';
  static const String premiumPrice = 'UGX 50,000/mo';

  // Home
  static const String todaysSales = "Today's Sales";
  static const String newSale = 'New Sale';
  static const String stockIn = 'Stock In';
  static const String scan = 'Scan';
  static const String reports = 'Reports';
  static const String recentSales = 'Recent Sales';
  static const String seeAll = 'See all';
  static const String itemsRunningLow = 'items running low';

  // Navigation
  static const String home = 'Home';
  static const String inventory = 'Inventory';
  static const String customers = 'Customers';

  // Inventory
  static const String totalItems = 'Total Items';
  static const String lowStock = 'Low Stock';
  static const String stockValue = 'Stock Value';
  static const String searchItems = 'Search items...';
  static const String addNewItem = 'Add New Item';
  static const String itemName = 'Item Name';
  static const String category = 'Category';
  static const String barcode = 'Barcode';
  static const String buyingPrice = 'Buying Price';
  static const String sellingPrice = 'Selling Price';
  static const String currentStock = 'Current Stock';
  static const String reorderLevel = 'Reorder Level';
  static const String saveItem = 'Save Item';
  static const String tapToAddPhoto = 'Tap to add photo';

  // Sale
  static const String searchProducts = 'Search products...';
  static const String cartTotal = 'Cart Total';
  static const String checkout = 'Checkout';
  static const String saleComplete = 'Sale Complete!';
  static const String transaction = 'Transaction';
  static const String print = 'Print';
  static const String share = 'Share';
  static const String thankYou = 'Thank you for shopping with us!';
  static const String cash = 'Cash';
  static const String mobileMoney = 'Mobile Money';
  static const String credit = 'Credit';

  // Customers
  static const String customerDebts = 'Customer Debts';
  static const String totalOwed = 'Total Owed';
  static const String overdue = 'Overdue';
  static const String remind = 'Remind';
  static const String addPayment = 'Add Payment';
  static const String dueDate = 'Due';
  static const String daysOverdue = 'days overdue';
  static const String onTrack = 'On track';

  // Reports
  static const String businessReports = 'Business Reports';
  static const String today = 'Today';
  static const String week = 'Week';
  static const String month = 'Month';
  static const String year = 'Year';
  static const String totalSales = 'Total Sales';
  static const String grossProfit = 'Gross Profit';
  static const String transactions = 'Transactions';
  static const String salesTrend = 'Sales Trend';

  // Settings
  static const String settings = 'Settings';
  static const String businessProfile = 'Business Profile';
  static const String staffAccounts = 'Staff Accounts';
  static const String receiptSettings = 'Receipt Settings';
  static const String notifications = 'Notifications';
  static const String autoBackup = 'Auto Backup';
  static const String biometricLock = 'Biometric Lock';
  static const String helpCenter = 'Help Center';
  static const String logOut = 'Log Out';
  static const String upgradePlan = 'Upgrade Plan';

  // Subscription Plans
  static const String recommended = 'RECOMMENDED';
  static const String starterPlan = 'Starter Plan';
  static const String freeTrial = '🎁 14-day free trial included!';
  static const String startFreeTrial = 'Start Free Trial';
  static const String startWithFreePlan = 'Start with Free Plan';

  // General
  static const String currency = 'UGX';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String confirm = 'Confirm';
  static const String loading = 'Loading...';
  static const String noData = 'No data available';
  static const String retry = 'Retry';
  static const String offline = 'You are offline';
  static const String syncing = 'Syncing...';
  static const String synced = 'All changes synced';
  static const String all = 'All';
  static const String useCurrentLocation = 'Use my current location';
  static const String businessName = 'Business Name';
  static const String ownerName = "Owner's Name";
  static const String businessPhone = 'Business Phone';
  static const String tinNumber = 'TIN Number (Optional)';
  static const String district = 'District';
  static const String area = 'Area/Neighborhood';
}
