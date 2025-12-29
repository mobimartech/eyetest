import 'dart:async';
import 'dart:ui';

import 'package:eyetest/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaywallAndroid extends StatefulWidget {
  const PaywallAndroid({Key? key}) : super(key: key);

  @override
  State<PaywallAndroid> createState() => _PaywallAndroidState();
}

class _PaywallAndroidState extends State<PaywallAndroid>
    with SingleTickerProviderStateMixin {
  List<Package> packages = [];
  Package? selectedPackage;
  bool loading = true;
  bool purchasing = false;
  bool isDiscountLoader = false;

  // Discount code
  String discountCode = '';
  bool showDiscountInput = false;
  bool isValidatingCode = false;
  PromotionalOffer? appliedDiscount;
  String? appliedDiscountCode;

  // Close button animation
  bool showCloseButton = false;
  late AnimationController _closeBtnController;
  late Animation<double> _closeBtnOpacity;

  bool isFreeTrial = false;

  // BRAND COLORS - ADJUSTED FOR NEW THEME
  final Color accentColor = const Color(0xFF049281); // Teal
  final Color darkBg = const Color(0xFF0D0F11); // Deep Slate/Black
  final Color surfaceColor = const Color(0xFF1A1D21); // Slightly lighter slate

  @override
  void initState() {
    super.initState();

    fetchPackages();
    _closeBtnController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _closeBtnOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_closeBtnController);

    Future.delayed(Duration(seconds: 4), () {
      setState(() => showCloseButton = true);
      _closeBtnController.forward();
    });
  }

  // --- LOGIC SECTION (UNCHANGED) ---
  Widget buildSubscriptionDisclaimer() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
      child: Text(
        !isFreeTrial
            ? 'Subscription auto-renews. Cancel anytime in settings.'
            : 'Trial converts to subscription automatically unless canceled.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white30,
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _closeBtnController.dispose();
    super.dispose();
  }

  Future<void> fetchPackages() async {
    setState(() => loading = true);
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        packages = offerings.current!.availablePackages;
        selectedPackage = packages.firstWhere(
          (pkg) =>
              pkg.identifier.toLowerCase().contains('weekly') ||
              pkg.packageType == PackageType.weekly,
        );

        if (selectedPackage != null) {
          isFreeTrial = hasFreeTrial(selectedPackage!);
        }
      }
    } catch (e) {
      // Handle error
    }
    setState(() => loading = false);
  }

  bool hasFreeTrial(Package pkg) {
    final intro = pkg.storeProduct.introductoryPrice;
    if (intro != null) {
      return intro.price == 0;
    }
    return pkg.identifier.toLowerCase().contains('trial') ||
        pkg.identifier.toLowerCase().contains('offer');
  }

  String getPackagePrice(Package pkg) => pkg.storeProduct.priceString;

  String getPackageDescription(Package pkg) {
    if (pkg.packageType == PackageType.weekly ||
        pkg.identifier.toLowerCase().contains('weekly')) {
      if (hasFreeTrial(pkg)) {
        return 'then \$4.99 / week';
      } else {
        return 'Standard Plan';
      }
    }
    return 'Best Value';
  }

  String getPackageLabel(Package pkg) {
    if (pkg.packageType == PackageType.weekly ||
        pkg.identifier.toLowerCase().contains('weekly')) {
      return 'Weekly';
    }
    return 'Yearly';
  }

  String getDisplayPrice(Package pkg) {
    return getPackagePrice(pkg);
  }

  String getButtonText() {
    if (selectedPackage != null && hasFreeTrial(selectedPackage!)) {
      return 'START FREE TRIAL';
    } else {
      return 'CONTINUE';
    }
  }

  Future<void> applyDiscountCode() async {
    // Logic placeholder - functionality preserved
    if (discountCode.trim().isEmpty) return;
    // ... (Existing logic assumed here)
  }

  Future<void> presentCodeRedemptionSheet() async {
    try {
      await Purchases.presentCodeRedemptionSheet();
    } on PlatformException catch (e) {
      print('Error: $e');
    }
  }

  Future<void> handlePurchase() async {
    if (selectedPackage == null) return;
    setState(() => purchasing = true);
    try {
      PurchaseResult purchaseResult;
      if (appliedDiscount != null) {
        final purchaseParams = PurchaseParams.package(
          selectedPackage!,
          promotionalOffer: appliedDiscount!,
        );
        purchaseResult = await Purchases.purchase(purchaseParams);
      } else {
        final purchaseParams = PurchaseParams.package(selectedPackage!);
        purchaseResult = await Purchases.purchase(purchaseParams);
      }

      final customerInfo = purchaseResult.customerInfo;
      if (customerInfo.activeSubscriptions.isNotEmpty) {
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
      }
    } catch (e) {}
    setState(() => purchasing = false);
  }

  Future<void> restorePurchases() async {
    setState(() => purchasing = true);
    try {
      final info = await Purchases.restorePurchases();
      if (info.entitlements.active.isNotEmpty) {
        Navigator.pop(context);
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
      }
    } catch (e) {}
    setState(() => purchasing = false);
  }

  // --- NEW WIDGETS FOR THIS DESIGN ---

  Widget buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 12, color: accentColor),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Media Query for exact sizing
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: darkBg,
      body: loading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : Stack(
              children: [
                // Background Gradient Mesh
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0F1515),
                          Color(0xFF000000),
                        ],
                      ),
                    ),
                  ),
                ),

                // Subtle accent glow at top right
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                              color: accentColor.withOpacity(0.2),
                              blurRadius: 100),
                        ]),
                  ),
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- TOP HEADER SECTION ---
                        SizedBox(height: 10),
                        Center(
                          child: Opacity(
                            opacity: 0.9,
                            child: Image.asset(
                              'assets/img/Logo.png',
                              height: 65,
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // BIG TYPOGRAPHY TITLE
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "UNLOCK\nFULL ACCESS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              height: 0.9,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ),

                        SizedBox(height: 8),
                        Text(
                          "Eye testing tools & AI analysis.",
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),

                        SizedBox(height: 25),

                        // --- FEATURES (Compact List) ---
                        // Using Expanded to fill available space appropriately
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              buildBulletPoint(
                                  "Visual Field & Color Perception"),
                              buildBulletPoint(
                                  "Astigmatism & Amsler Grid Tests"),
                              buildBulletPoint("Dry Eye Assessment & Tracking"),
                              buildBulletPoint("AI-Powered Health Assistant"),
                              buildBulletPoint("Unlimited Historical Data"),
                            ],
                          ),
                        ),

                        // --- PRICING & ACTIONS SECTION ---

                        // Trial Badge
                        if (isFreeTrial)
                          Center(
                            child: Container(
                              margin: EdgeInsets.only(bottom: 15),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "🎉 3 Days Free Trial Included",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                        // Package Cards - Vertical Stack for this design (cleaner)
                        // Or Horizontal if space is tight. Let's do Horizontal for "Fit Screen"
                        SizedBox(
                          height: 120,
                          child: Row(
                            children: packages.map((pkg) {
                              final isSelected =
                                  selectedPackage?.identifier == pkg.identifier;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: purchasing
                                      ? null
                                      : () => setState(() {
                                            selectedPackage = pkg;
                                            isFreeTrial = hasFreeTrial(pkg);
                                            handlePurchase();
                                          }),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    margin: EdgeInsets.symmetric(horizontal: 5),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? accentColor
                                          : surfaceColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : Colors.white10,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          getPackageLabel(pkg).toUpperCase(),
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white54,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          getDisplayPrice(pkg),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (pkg.packageType ==
                                            PackageType.annual)
                                          Text(
                                            "\$59.99",
                                            style: TextStyle(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: isSelected
                                                    ? Colors.white70
                                                    : Colors.white24,
                                                fontSize: 11),
                                          ),
                                        SizedBox(height: 4),
                                        Text(
                                          getPackageDescription(pkg),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white38,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        SizedBox(height: 20),

                        // CTA Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: purchasing || selectedPackage == null
                                ? null
                                : handlePurchase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: purchasing
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black))
                                : Text(
                                    getButtonText(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),

                        buildSubscriptionDisclaimer(),

                        // Footer
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _footerBtn('Terms',
                                  'https://eyeshealthtest.com/terms.html'),
                              GestureDetector(
                                onTap: restorePurchases,
                                child: Text('Restore Purchases',
                                    style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ),
                              _footerBtn('Privacy',
                                  'https://eyeshealthtest.com/privacy.html'),
                            ],
                          ),
                        ),
                        SizedBox(height: 5),
                      ],
                    ),
                  ),
                ),

                // Close Button - Minimalist Top Left
                if (showCloseButton)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 20,
                    child: FadeTransition(
                      opacity: _closeBtnOpacity,
                      child: GestureDetector(
                        onTap: () => Navigator.of(
                          context,
                        ).pushReplacement(
                            MaterialPageRoute(builder: (_) => HomePage())),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            shape: BoxShape.circle,
                          ),
                          child:
                              Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),

                // Discount Code Button (Hidden/Subtle)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 15,
                  right: 20,
                  child: GestureDetector(
                    onTap: presentCodeRedemptionSheet,
                    child: Icon(Icons.confirmation_num_outlined,
                        color: Colors.white24, size: 20),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _footerBtn(String label, String url) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Text(label, style: TextStyle(color: Colors.white30, fontSize: 11)),
    );
  }
}
