import 'dart:async';

import 'package:eyetest/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({Key? key}) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
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

    Future.delayed(Duration(seconds: 5), () {
      setState(() => showCloseButton = true);
      _closeBtnController.forward();
    });
  }

  Widget buildSubscriptionDisclaimer() {
    return Container(
      // padding: EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Text(
        !isFreeTrial
            ? 'Once you subscribe, the subscription will commence immediately. You have the option to cancel at any time. Subscriptions will be automatically renewed unless you disable auto-renewal at least 24 hours prior to the end of the current period.'
            : 'After free trial ends, the subscription will commence immediately. You have the option to cancel at any time. Subscriptions will be automatically renewed unless you disable auto-renewal at least 24 hours prior to the end of the current period.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 9,
          fontWeight: FontWeight.w400,
          height: 1.4,
          letterSpacing: 0.1,
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
        // Pre-select weekly if available
        selectedPackage = packages.firstWhere(
          (pkg) =>
              pkg.identifier.toLowerCase().contains('weekly') ||
              pkg.packageType == PackageType.weekly,
        );

        // Set isFreeTrial based on selected package
        if (selectedPackage != null) {
          isFreeTrial = hasFreeTrial(selectedPackage!);
        }

        // PRINT ALL PROMOTIONAL OFFER CODES FOR EACH PACKAGE
        for (final pkg in packages) {
          print('Package: ${pkg.identifier}');
          final discounts = pkg.storeProduct.discounts;
          if (discounts != null && discounts.isNotEmpty) {
            for (final discount in discounts) {
              print('  Promo code: ${discount.identifier}');
            }
          } else {
            print('  No promo codes for this package.');
          }
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

  String getTrialDuration(Package pkg) {
    final intro = pkg.storeProduct.introductoryPrice;
    if (intro != null && intro.period != null) {
      final period = intro.period!;
      if (period.contains('P3D')) return '3-Day';
      if (period.contains('P7D')) return '7-Day';
      if (period.contains('P1W')) return '1-Week';
      if (period.contains('P2W')) return '2-Week';
    }
    return '3-Day';
  }

  String getPackagePrice(Package pkg) => pkg.storeProduct.priceString;

  String getPackageDescription(Package pkg) {
    if (pkg.packageType == PackageType.weekly ||
        pkg.identifier.toLowerCase().contains('weekly')) {
      if (hasFreeTrial(pkg)) {
        // isFreeTrial = true;

        return 'then \$4.99/week';
      } else {
        return 'Get Started Now!';
      }
    }
    return 'Best Deal!';
  }

  String getPackageLabel(Package pkg) {
    if (pkg.packageType == PackageType.weekly ||
        pkg.identifier.toLowerCase().contains('weekly')) {
      if (hasFreeTrial(pkg)) {
        // isFreeTrial = true;

        return 'Weekly';
      } else {
        return 'Weekly';
      }
    }
    return 'Yearly';
  }

  String getDisplayPrice(Package pkg) {
    return getPackagePrice(pkg);
  }

  String getButtonText() {
    // Remove the setState calls from here
    if (selectedPackage != null && hasFreeTrial(selectedPackage!)) {
      return 'Start Free Trial';
    } else {
      return 'Continue';
    }
  }

  Future<void> applyDiscountCode() async {
    if (discountCode.trim().isEmpty) {
      _showAlert('Error', 'Please enter a discount code');
      return;
    }

    setState(() => isValidatingCode = true);

    try {
      // Find the discount
      final discount = selectedPackage!.storeProduct.discounts!.firstWhere(
        (d) => d.identifier.toUpperCase() == discountCode.trim().toUpperCase(),
        orElse: () => throw Exception('Discount code not found'),
      );

      print('✅ Discount found: ${discount.identifier}');

      // Request promotional offer
      print('🔑 Requesting promotional offer signature...');
      final offer = await Purchases.getPromotionalOffer(
        selectedPackage!.storeProduct,
        discount,
      );

      if (offer != null) {
        print('✅ Promotional offer obtained successfully');
        setState(() {
          appliedDiscount = offer;
          appliedDiscountCode = discountCode.trim();
          showDiscountInput = false;
        });
        _showAlert('Success', 'Discount code applied successfully!');
      } else {
        print('❌ ERROR: getPromotionalOffer returned null');
        print('⚠️ This usually means:');
        print('   1. In-App Purchase Key not configured in RevenueCat');
        print('   2. Promotional offer not set up in App Store Connect');
        print('   3. Key ID/Issuer ID mismatch');

        _showAlert(
          'Configuration Error',
          'Unable to apply discount. Please ensure:\n\n'
              '• In-App Purchase Key is configured in RevenueCat\n'
              '• Promotional offer exists in App Store Connect\n\n'
              'Contact support if the issue persists.',
        );
      }
    } catch (e, stackTrace) {
      print('❌ Exception: $e');
      print('Stack: $stackTrace');
      _showAlert('Invalid Code', 'This discount code is not valid: $e');
    }

    setState(() => isValidatingCode = false);
  }

  Future<void> presentCodeRedemptionSheet() async {
    try {
      print('🎁 Presenting code redemption sheet...');
      await Purchases.presentCodeRedemptionSheet();
    } on PlatformException catch (e) {
      print('Error presenting code redemption sheet: $e');
    }
  }

  void removeDiscount() {
    setState(() {
      appliedDiscount = null;
      appliedDiscountCode = null;
      discountCode = '';
    });
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
    } on PurchasesErrorCode catch (e) {
      // if (e != PurchasesErrorCode.purchaseCancelledError) {
      //   _showAlert('Error', 'Unable to complete purchase. Please try again.');
      // }
    } catch (e) {
      // _showAlert('Error', 'Unable to complete purchase. Please try again.');
    }
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
      } else {
        _showAlert(
          'No purchases found',
          'No active subscriptions were found to restore.',
        );
      }
    } catch (e) {
      //_showAlert('Error', 'Unable to restore purchases. Please try again.');
    }
    setState(() => purchasing = false);
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF121212),
                Color(0xFF049281).withOpacity(0.15),
                Colors.black,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0xFF049281), width: 2),
            boxShadow: [
              BoxShadow(
                color: Color(0x80049281),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFF049281),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  color: Color(0xFF049281),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF049281),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDiscountSection() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () async {
          await presentCodeRedemptionSheet();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Color(0x1A049281),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0x4D049281),
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎁', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Have a discount code?',
                style: TextStyle(
                  color: Color(0xFF049281),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF049281), Color(0xFF037268)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Color(0x40049281),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 12),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: loading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF049281)))
          : Stack(
              children: [
                // Gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF049281),
                        Color(0x33000000),
                        Color(0xFF121212),
                        Colors.black,
                      ],
                      stops: [0, 0.6, 0.7, 1],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      // Close button
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              SizedBox(height: 10),
                              // Logo
                              Center(
                                child: Image.asset(
                                  'assets/img/Logo.png',
                                  width: 100,
                                  height: 100,
                                ),
                              ),
                              SizedBox(height: 24),
                              // Title and Subtitle
                              Text(
                                'Test & Improve Your Vision',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '🎯 Track vision progress',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF049281),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 24),

                              // Features Title
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.center,
                              //   children: [
                              //     Container(
                              //       padding: EdgeInsets.all(6),
                              //       decoration: BoxDecoration(
                              //         gradient: LinearGradient(
                              //           colors: [
                              //             Color(0xFF049281),
                              //             Color(0xFF037268),
                              //           ],
                              //         ),
                              //         borderRadius: BorderRadius.circular(8),
                              //         boxShadow: [
                              //           BoxShadow(
                              //             color: Color(0x60049281),
                              //             blurRadius: 12,
                              //             offset: Offset(0, 4),
                              //           ),
                              //         ],
                              //       ),
                              //       child: Icon(
                              //         Icons.stars_rounded,
                              //         color: Colors.white,
                              //         size: 20,
                              //       ),
                              //     ),
                              //     SizedBox(width: 10),

                              //     // ShaderMask(
                              //     //   shaderCallback: (bounds) => LinearGradient(
                              //     //     colors: [Colors.white, Color(0xFF049281)],
                              //     //   ).createShader(bounds),
                              //     //   child: Text(
                              //     //     'Everything You\'ll Get',
                              //     //     style: TextStyle(
                              //     //       fontSize: 20,
                              //     //       fontWeight: FontWeight.bold,
                              //     //       color: Colors.white,
                              //     //       letterSpacing: 0.5,
                              //     //     ),
                              //     //   ),
                              //     // ),
                              //   ],
                              // ),
                              // SizedBox(height: 16),

                              // Features grid - 2 per row
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: buildFeatureItem(
                                          Icons.grid_on_rounded,
                                          'Visual Field Analysis',
                                        ),
                                      ),
                                      Expanded(
                                        child: buildFeatureItem(
                                          Icons.palette_rounded,
                                          'Color Perception Test',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: buildFeatureItem(
                                          Icons.visibility_rounded,
                                          'Astigmatism Screening',
                                        ),
                                      ),
                                      Expanded(
                                        child: buildFeatureItem(
                                          Icons.apps_rounded,
                                          'Amsler Grid Evaluation',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: buildFeatureItem(
                                          Icons.water_drop_outlined,
                                          'Dry Eye Assessment',
                                        ),
                                      ),
                                      Expanded(
                                        child: buildFeatureItem(
                                          Icons.chat_bubble_outline_rounded,
                                          'AI Eye-Health Assistant',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              isFreeTrial
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shield_outlined,
                                          color: Color.fromARGB(
                                            255,
                                            5,
                                            244,
                                            216,
                                          ),
                                          size: 17,
                                        ),
                                        Text(
                                          'Enjoy 3 Days Free, then ${getDisplayPrice(selectedPackage!)}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : SizedBox.shrink(),
                              // Pricing options
                              isFreeTrial
                                  ? SizedBox(height: 10)
                                  : SizedBox.shrink(),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final cardWidth = constraints.maxWidth * 0.45;
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: packages.map((pkg) {
                                      final isSelected =
                                          selectedPackage?.identifier ==
                                              pkg.identifier;
                                      return Container(
                                        // width: cardWidth,
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: GestureDetector(
                                          onTap: purchasing
                                              ? null
                                              : () => setState(() {
                                                    selectedPackage = pkg;
                                                    isFreeTrial = hasFreeTrial(
                                                      pkg,
                                                    ); // Add this line
                                                    handlePurchase();
                                                  }),
                                          child: AnimatedContainer(
                                            duration: Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Color(0x28049281)
                                                  : Colors.white10,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Color(0xFF049281)
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: Color(
                                                          0x80049281,
                                                        ),
                                                        blurRadius: 16,
                                                        offset: Offset(0, 6),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: Stack(
                                              children: [
                                                if (isSelected)
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: Container(
                                                      width: 24,
                                                      height: 24,
                                                      decoration: BoxDecoration(
                                                        color: Color(
                                                          0xFF049281,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          12,
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '✓',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      getPackageLabel(pkg),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          getDisplayPrice(pkg),
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        SizedBox(width: 2),
                                                        (pkg.packageType ==
                                                                PackageType
                                                                    .annual)
                                                            ? Text(
                                                                "\$59.99",
                                                                style:
                                                                    TextStyle(
                                                                  color: const Color
                                                                      .fromARGB(
                                                                    255,
                                                                    249,
                                                                    33,
                                                                    29,
                                                                  ),
                                                                  fontSize: 10,
                                                                  // fontWeight:
                                                                  //     FontWeight
                                                                  //         .bold,
                                                                  decoration:
                                                                      TextDecoration
                                                                          .lineThrough,
                                                                ),
                                                              )
                                                            : SizedBox.shrink(),
                                                      ],
                                                    ),
                                                    SizedBox(height: 6),
                                                    Text(
                                                      getPackageDescription(
                                                        pkg,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF049281,
                                                        ),
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),

                              SizedBox(height: 20),
                              // // Discount code section
                              // buildDiscountSection(),
                              // Purchase button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF049281),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 18),
                                  ),
                                  onPressed:
                                      purchasing || selectedPackage == null
                                          ? null
                                          : handlePurchase,
                                  child: purchasing
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          getButtonText(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              // SizedBox(height: 24),
                              SizedBox(height: 5),
                              buildSubscriptionDisclaimer(),
                              // Footer links
                              // SizedBox(height: 5),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  TextButton(
                                    onPressed: () => launchUrl(
                                      Uri.parse(
                                        'https://eyeshealthtest.com/terms.html',
                                      ),
                                    ),
                                    child: Text(
                                      'Terms',
                                      style: TextStyle(
                                        color: Color(0xFF049281),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: restorePurchases,
                                    child: Text(
                                      'Restore',
                                      style: TextStyle(
                                        color: Color(0xFF049281),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => launchUrl(
                                      Uri.parse(
                                        'https://eyeshealthtest.com/privacy.html',
                                      ),
                                    ),
                                    child: Text(
                                      'Privacy',
                                      style: TextStyle(
                                        color: Color(0xFF049281),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showCloseButton)
                  SafeArea(
                    child: FadeTransition(
                      opacity: _closeBtnOpacity,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 20,
                            left: 20,
                            bottom: 10,
                          ),
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 30,
                              height: 30,
                              child: Center(
                                child: Text(
                                  '×',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class PaywallPackageCard extends StatelessWidget {
  final Package package;
  final bool isSelected;
  final VoidCallback? onTap;
  final String label;
  final String price;
  final String description;
  final bool isBest;

  const PaywallPackageCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
    required this.label,
    required this.price,
    required this.description,
    this.isBest = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Color(0xFF049281), Color(0xFF0E3C36)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.white10, Colors.black12],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0x80049281),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
          border: Border.all(
            color: isSelected ? Color(0xFF049281) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBest)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF049281),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Best Value',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(height: isBest ? 10 : 0),
            Icon(
              Icons.star_rounded,
              color: isSelected ? Colors.yellow[700] : Colors.white24,
              size: 32,
            ),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF049281),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
